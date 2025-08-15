import unittest
import json
import base64
import gzip
import io
from unittest.mock import patch, MagicMock

# lambda_function.py から正しい関数名でimport
from lambda_function import handler, process_firehose_records, transform_log_event

class TestLambdaFunction(unittest.TestCase):

    def create_test_event(self, message_type="DATA_MESSAGE"):
        """CloudWatch LogsからFirehose経由でLambdaに渡るイベントを生成"""
        log_events = [
            {
                "id": "01234567890123456789012345678901234567890123456789012345",
                "timestamp": 1510109208016,
                "message": "test log message 1"
            },
            {
                "id": "01234567890123456789012345678901234567890123456789012345",
                "timestamp": 1510109208017,
                "message": "test log message 2"
            }
        ]

        cwl_data = {
            "messageType": message_type,
            "owner": "123456789012",
            "logGroup": "test_log_group",
            "logStream": "test_log_stream",
            "subscriptionFilters": ["test_filter"],
            "logEvents": log_events
        }

        compressed_data = io.BytesIO()
        with gzip.GzipFile(fileobj=compressed_data, mode='w') as f:
            f.write(json.dumps(cwl_data).encode('utf-8'))

        compressed_data.seek(0)
        base64_data = base64.b64encode(compressed_data.read()).decode('utf-8')

        return {
            "deliveryStreamArn": "arn:aws:firehose:us-east-1:123456789012:deliverystream/test-stream",
            "records": [
                {
                    "recordId": "test-record-id",
                    "data": base64_data
                }
            ]
        }

    @patch('boto3.client')
    def test_handler_data_message(self, mock_boto3_client):
        """DATA_MESSAGE のイベントが正常に処理されることをテスト"""
        mock_client = MagicMock()
        mock_boto3_client.return_value = mock_client

        event = self.create_test_event()
        result = handler(event, {})

        self.assertIn("records", result)
        self.assertEqual(len(result["records"]), 1)
        self.assertEqual(result["records"][0]["result"], "Ok")
        self.assertIn("data", result["records"][0])

    @patch('boto3.client')
    def test_handler_control_message(self, mock_boto3_client):
        """CONTROL_MESSAGE のイベントが Dropped 扱いになることをテスト"""
        mock_client = MagicMock()
        mock_boto3_client.return_value = mock_client

        event = self.create_test_event(message_type="CONTROL_MESSAGE")
        result = handler(event, {})

        self.assertIn("records", result)
        self.assertEqual(len(result["records"]), 1)
        self.assertEqual(result["records"][0]["result"], "Dropped")

    def test_transform_log_event(self):
        """transform_log_event の出力が期待通りであることをテスト"""
        log_event = {
            "id": "01234567890123456789012345678901234567890123456789012345",
            "timestamp": 1510109208016,
            "message": "test log message"
        }

        result = transform_log_event(log_event)
        self.assertIsInstance(result, str)
        self.assertTrue(result.endswith('\n'))

        # 改行を除いて逆変換できるか
        parsed_result = json.loads(result.strip())
        self.assertEqual(parsed_result["id"], log_event["id"])
        self.assertEqual(parsed_result["timestamp"], log_event["timestamp"])
        self.assertEqual(parsed_result["message"], log_event["message"])

if __name__ == '__main__':
    unittest.main()
