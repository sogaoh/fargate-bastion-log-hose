
"""
For processing data sent to Firehose by Cloudwatch Logs subscription filters.

Cloudwatch Logs sends to Firehose records that look like this:

{
  "messageType": "DATA_MESSAGE",
  "owner": "123456789012",
  "logGroup": "log_group_name",
  "logStream": "log_stream_name",
  "subscriptionFilters": [
    "subscription_filter_name"
  ],
  "logEvents": [
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208016,
      "message": "log message 1"
    },
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208017,
      "message": "log message 2"
    }
    ...
  ]
}

The data is additionally compressed with GZIP.

The code below will:

1) Gunzip the data
2) Parse the json
3) Set the result to ProcessingFailed for any record whose messageType is not DATA_MESSAGE, thus redirecting them to the
   processing error output. Such records do not contain any log events. You can modify the code to set the result to
   Dropped instead to get rid of these records completely.
4) For records whose messageType is DATA_MESSAGE, extract the individual log events from the logEvents field, and pass
   each one to the transformLogEvent method. You can modify the transformLogEvent method to perform custom
   transformations on the log events.
5) Concatenate the result from (4) together and set the result as the data of the record returned to Firehose. Note that
   this step will not add any delimiters. Delimiters should be appended by the logic within the transformLogEvent
   method.
6) Any additional records which exceed 6MB will be re-ingested back into Firehose.

"""

# refs: https://github.com/htnosm/terraform-aws-cloudwatch-logs-to-s3/blob/main/src/kinesis-firehose-cloudwatch-logs-processor/lambda_function.py

import base64
import json
import gzip
import io
import boto3
from datetime import datetime, date


def json_serial(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError("Type %s is not JSON serializable" % type(obj))


def decode_base64_gzip_json(b64data):
    """base64+gzip+jsonのデータをデコードしてdictとして返す"""
    decoded = base64.b64decode(b64data)
    with gzip.GzipFile(fileobj=io.BytesIO(decoded), mode='r') as f:
        return json.loads(f.read())


def transform_log_event(log_event):
    """各ログイベントを変換（今回はJSON文字列+改行。他カスタムも可）"""
    message = json.dumps(log_event, default=json_serial, ensure_ascii=False)
    return message + '\n'


### Firehose/Kinesis再インジェストロジック関連（元のロジックを適切に関数化） ###
def create_reingestion_record(isSas, originalRecord):
    if isSas:
        return {'data': base64.b64decode(originalRecord['data']), 'partitionKey': originalRecord['kinesisRecordMetadata']['partitionKey']}
    else:
        return {'data': base64.b64decode(originalRecord['data'])}


def get_reingestion_record(isSas, reIngestionRecord):
    if isSas:
        return {'Data': reIngestionRecord['data'], 'PartitionKey': reIngestionRecord['partitionKey']}
    else:
        return {'Data': reIngestionRecord['data']}


def put_records_to_firehose_stream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ''
    response = None
    try:
        response = client.put_record_batch(DeliveryStreamName=streamName, Records=records)
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response['FailedPutCount'] > 0:
        for idx, res in enumerate(response['RequestResponses']):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if 'ErrorCode' not in res or not res['ErrorCode']:
                continue

            codes.append(res['ErrorCode'])
            failedRecords.append(records[idx])

        errMsg = 'Individual error codes: ' + ','.join(codes)

    if len(failedRecords) > 0:
        if attemptsMade + 1 < maxAttempts:
            print('Some records failed while calling PutRecordBatch to Firehose stream, retrying. %s' % (errMsg))
            put_records_to_firehose_stream(streamName, failedRecords, client, attemptsMade + 1, maxAttempts)
        else:
            raise RuntimeError('Could not put records after %s attempts. %s' % (str(maxAttempts), errMsg))


def put_records_to_kinesis_stream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ''
    # if put_records throws for whatever reason, response['xx'] will error out, adding a check for a valid
    # response will prevent this
    response = None
    try:
        response = client.put_records(StreamName=streamName, Records=records)
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response['FailedRecordCount'] > 0:
        for idx, res in enumerate(response['Records']):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if 'ErrorCode' not in res or not res['ErrorCode']:
                continue

            codes.append(res['ErrorCode'])
            failedRecords.append(records[idx])

        errMsg = 'Individual error codes: ' + ','.join(codes)

    if len(failedRecords) > 0:
        if attemptsMade + 1 < maxAttempts:
            print('Some records failed while calling PutRecords to Kinesis stream, retrying. %s' % (errMsg))
            put_records_to_kinesis_stream(streamName, failedRecords, client, attemptsMade + 1, maxAttempts)
        else:
            raise RuntimeError('Could not put records after %s attempts. %s' % (str(maxAttempts), errMsg))


### Firehose経由レコード処理（元ロジックを流用） ###
def process_firehose_records(records):
    for r in records:
        try:
            data_dict = decode_base64_gzip_json(r['data'])
        except Exception as e:
            yield {
                'result': 'ProcessingFailed',
                'recordId': r.get('recordId', 'UNKNOWN')
            }
            continue

        recId = r['recordId']
        if data_dict.get('messageType') == 'CONTROL_MESSAGE':
            yield {'result': 'Dropped', 'recordId': recId}
        elif data_dict.get('messageType') == 'DATA_MESSAGE':
            outdata = ''.join([transform_log_event(e) for e in data_dict['logEvents']])
            b64 = base64.b64encode(outdata.encode('utf-8'))
            yield {'data': b64, 'result': 'Ok', 'recordId': recId}
        else:
            yield {'result': 'ProcessingFailed', 'recordId': recId}


def handle_firehose_event(event):
    isSas = 'sourceKinesisStreamArn' in event
    streamARN = event['sourceKinesisStreamArn'] if isSas else event['deliveryStreamArn']
    print(f'streamARN: {streamARN}')
    region = streamARN.split(':')[3]
    streamName = streamARN.split('/')[1]
    records = list(process_firehose_records(event['records']))
    projectedSize = 0
    dataByRecordId = {rec['recordId']: create_reingestion_record(isSas, rec) for rec in event['records']}
    putRecordBatches = []
    recordsToReingest = []

    totalRecordsToBeReingested = 0
    for idx, rec in enumerate(records):
        if rec['result'] != 'Ok':
            continue
        projectedSize += len(rec['data']) + len(rec['recordId'])
        # 6000000 instead of 6291456 to leave ample headroom for the stuff we didn't account for
        if projectedSize > 6000000:
            totalRecordsToBeReingested += 1
            recordsToReingest.append(
                get_reingestion_record(isSas, dataByRecordId[rec['recordId']])
            )
            records[idx]['result'] = 'Dropped'
            del(records[idx]['data'])

        # split out the record batches into multiple groups, 500 records at max per group
        if len(recordsToReingest) == 500:
            putRecordBatches.append(recordsToReingest)
            recordsToReingest = []

    if len(recordsToReingest) > 0:
        # add the last batch
        putRecordBatches.append(recordsToReingest)

    # iterate and call putRecordBatch for each group
    recordsReingestedSoFar = 0
    if len(putRecordBatches) > 0:
        client = boto3.client('kinesis', region_name=region) if isSas else boto3.client('firehose', region_name=region)
        for recordBatch in putRecordBatches:
            if isSas:
                put_records_to_kinesis_stream(streamName, recordBatch, client, attemptsMade=0, maxAttempts=20)
            else:
                put_records_to_firehose_stream(streamName, recordBatch, client, attemptsMade=0, maxAttempts=20)
            recordsReingestedSoFar += len(recordBatch)
            print('Reingested %d/%d records out of %d' % (recordsReingestedSoFar, totalRecordsToBeReingested, len(event['records'])))
    else:
        print('No records to be reingested')

    return {"records": records}


### CloudWatch Logs直送用処理 ###
def handle_awslogs_event(event):
    logdata = decode_base64_gzip_json(event['awslogs']['data'])
    out_records = []
    for idx, log_event in enumerate(logdata.get('logEvents', [])):
        outdata = transform_log_event(log_event)
        # データ本体をbase64エンコード
        b64 = base64.b64encode(outdata.encode('utf-8')).decode('utf-8')
        # recordIdはeventごとにユニークな値を作るのがベター。ここでは連番で代用。
        record_id = log_event.get("id", f"logevent-{idx}")
        out_records.append({
            "recordId": record_id,
            "result": "Ok",
            "data": b64
        })
    return {"records": out_records}

### エントリポイント ###
def handler(event, context):
    if "awslogs" in event:
        print("[INFO] Receive direct from CloudWatch Logs (awslogs['data'])")
        return handle_awslogs_event(event)
    elif 'records' in event:
        print("[INFO] Receive from Firehose transform (records)")
        return handle_firehose_event(event)
    else:
        print("[WARN] Unknown event structure")
        print(json.dumps(event, ensure_ascii=False, indent=2))
        raise RuntimeError("Unrecognized event structure!")
