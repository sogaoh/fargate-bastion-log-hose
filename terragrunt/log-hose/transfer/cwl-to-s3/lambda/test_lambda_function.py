import unittest
import json
import base64
import gzip
import io
import boto3
from unittest.mock import patch, MagicMock
from lambda_function import handler, processRecords, transformLogEvent

class TestLambdaFunction(unittest.TestCase):
    
    def create_test_event(self, message_type="DATA_MESSAGE"):
        """Create a test event that simulates a CloudWatch Logs event."""
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
        
        # Compress the data as CloudWatch Logs would
        compressed_data = io.BytesIO()
        with gzip.GzipFile(fileobj=compressed_data, mode='w') as f:
            f.write(json.dumps(cwl_data).encode('utf-8'))
        
        compressed_data.seek(0)
        base64_data = base64.b64encode(compressed_data.read()).decode('utf-8')
        
        # Create the event that would be passed to the Lambda function
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
        """Test that the handler correctly processes DATA_MESSAGE events."""
        # Setup mock
        mock_client = MagicMock()
        mock_boto3_client.return_value = mock_client
        
        # Create test event
        event = self.create_test_event()
        
        # Call handler
        result = handler(event, {})
        
        # Verify results
        self.assertIn("records", result)
        self.assertEqual(len(result["records"]), 1)
        self.assertEqual(result["records"][0]["result"], "Ok")
        self.assertIn("data", result["records"][0])
    
    @patch('boto3.client')
    def test_handler_control_message(self, mock_boto3_client):
        """Test that the handler correctly processes CONTROL_MESSAGE events."""
        # Setup mock
        mock_client = MagicMock()
        mock_boto3_client.return_value = mock_client
        
        # Create test event with CONTROL_MESSAGE
        event = self.create_test_event(message_type="CONTROL_MESSAGE")
        
        # Call handler
        result = handler(event, {})
        
        # Verify results
        self.assertIn("records", result)
        self.assertEqual(len(result["records"]), 1)
        self.assertEqual(result["records"][0]["result"], "Dropped")
    
    def test_transform_log_event(self):
        """Test that transformLogEvent correctly transforms a log event."""
        log_event = {
            "id": "01234567890123456789012345678901234567890123456789012345",
            "timestamp": 1510109208016,
            "message": "test log message"
        }
        
        result = transformLogEvent(log_event)
        
        # Verify the result is a string and ends with a newline
        self.assertIsInstance(result, str)
        self.assertTrue(result.endswith('\n'))
        
        # Verify the result can be parsed back to the original log event
        parsed_result = json.loads(result.strip())
        self.assertEqual(parsed_result["id"], log_event["id"])
        self.assertEqual(parsed_result["timestamp"], log_event["timestamp"])
        self.assertEqual(parsed_result["message"], log_event["message"])

if __name__ == '__main__':
    unittest.main()