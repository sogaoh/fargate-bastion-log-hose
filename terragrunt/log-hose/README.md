## log-hose 

CloudWatch Logs を S3 に転送する機構のサンプル

- CloudWatch Logs には参照するであろう１ヶ月程度は残す
- S3 には監査目的等で長期的に残す必要があるものを保管

というときに利用する想定の機構


### 参考にしたリポジトリ・記事

- https://github.com/htnosm/terraform-aws-cloudwatch-logs-to-s3
- https://n-s.tokyo/2025/03/20250301/


### 構築方法

- _provider.tf と _variables.tf を _example_ を参考に準備してください

- terragrunt/log-hose/storage/s3-terminal
    - 最終保管する S3 
        - ライフサイクル設定を軽く突っ込んであります
            - GIR に移行する・削除する、の期間（locals.tf、適当なのでちゃんと変えてください）
- terragrunt/log-hose/transfer/cwl-to-s3
    - CloudWatch Logs -> Subscription Filter -> (Lambda ->) Firehose -> S3 のリソース群
        - ややこしいのは IAM  
- terragrunt/log-hose/transfer/cwl-to-s3/lambda
    - Lambda の Python (3.12) ソースコードとテストコード
        - データに加工が必要になった際に適宜手を加えてください
        - deploy ディレクトリで以下手順を実行すればデプロイできます（lambroll 利用）
            1. cd /path/to/lambda/deploy
            2. direnv allow   # .envrc を作り込んでから。1項目
            3. make build 
            4. make deploy
            5. (make clean)   # 中間ファイルの掃除



