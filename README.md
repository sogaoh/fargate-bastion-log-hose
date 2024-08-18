# fargate-bastion-mysql-client

MySQL操作用お手軽踏み台クライアント


## これは何？

- AWS で MySQL DB を操作したい場合に、ガッ、と「プライベートサブネット」に置く Fargate を構築するための IaC コード一式 
    - 参考情報  
      - [ECSタスクの単発実行によるオンデマンド踏み台サーバーの実現 - UZABASE for Engineers 2024-06-12](https://tech.uzabase.com/entry/2024/06/12/151044)
      - [踏み台にはECSコンテナを。～ログイン有無を検知して自動停止させる～ - NRIネットコムBlog 2023-10-02](https://tech.nri-net.com/entry/ecs_container_stepping_stone)

- Terraform でこれ系の構築事例が見当たらなかったので Terragrunt 入門の手始めに良さそうで、やってみた


## PreRequirements: 前提 

- macOS or Linux

### クライアントツールとして利用するのに必要な最低限

- [AWS CLI v2](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/install-cliv2.html)
    - (+) [Session Manager Plugin](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [direnv](https://direnv.net/) (load and unload environment variables on current directory)
- [ecspresso v2](https://github.com/kayac/ecspresso) (ECS deploy tool)
    - Guide -> [ecspresso handbook v2対応版](https://zenn.dev/fujiwara/books/ecspresso-handbook-v2) ※ ¥500


### リソース整備・機構構築に必要な開発ツール

- [tgenv](https://github.com/tgenv/tgenv) (for terragrunt setup)
- [tfenv](https://github.com/tfutils/tfenv) (for terraform setup)
- [Docker Desktop](https://matsuand.github.io/docs.docker.jp.onthefly/desktop/)


## Configurations: 設定

自身の環境に合わせて設定しておくファイル

### クライアントツール利用時

- /path/to/deploy/ecspresso/live/.envrc
    - `.envrc.example` にある項目を適宜設定してください  


### ローカルで bastion-client を docker compose で動かしてみるとき

- /path/to/deploy/.envrc
    - `AWS_ACCOUNT_ID` を適切に設定してください


### ECS Task を実行するためのリソース一式を構築するとき

- /path/to/terragrunt/live/manage/iam/role/task-exec
    - `_variables.tf`
        - profile を適切に設定してください
        - env_identifier を適切に設定してください (dev/stg/prdなど)

- /path/to/terragrunt/live/resource/ecr
    - `_variables.tf` 
        - profile を適切に設定してください

- /path/to/terragrunt/live/resource/ecs-cluster
    - `_variables.tf`
        - profile を適切に設定してください
        - env_identifier を適切に設定してください (dev/stg/prdなど)
    - `_locals.tf`
        - ecs_cluster_name・ecs_exec_logs_name を適切に設定してください
            - ${var.env_identifier} 利用可能  
        - container_insights_state を設定してください ("disabled"/"enabled")


## Usage: クライアントツール利用方法

### AWS 認証

```bash
aws sts get-caller-identity
```

で妥当に UserId・Account・Arn が表示されている状態としてください


### ECS Task を実行可能かを ecspresso verify

```bash
cd /path/to/deploy/ecspresso/live
```

```bash
direnv allow
```

```bash
make verify
```

### ECS Task を実行: ecspresso run

```bash
cd /path/to/deploy/ecspresso/live
```

```bash
direnv allow
```

```bash
make run
```

ECS Task が起動します。  
デフォルトで 900秒 (15分) ECS Exec での接続がなければ自動で Task が終了します。


### ECS Exec で bastion-client に接続: ecspresso exec

```bash
cd /path/to/deploy/ecspresso/live
```

```bash
direnv allow
```

```bash
make exec
```

起動している ECS Task に接続して、mysql クライアントを利用することができます。


## Build: 関連リソース構築方法

### AWS 認証

```bash
aws sts get-caller-identity
```

で妥当に UserId・Account・Arn が表示されている状態としてください


### Terragrunt でリソースを構築

```bash
cd /path/to/terragrunt
```

```bash
terragrunt run-all apply
```

Configuration が妥当に出来上がっていれば、  
- ECR リポジトリ
- ECS Task 実行ロール（IAM）
- ECS クラスター

が作成されます。


### Docker で ECR に bastion-client のイメージを push

```bash
cd /path/to/deploy
```

```bash
make ecr-pub-login
```

docker build 時に ECR Public を参照するので認証が必要です


```bash
make ecr-login
```

ECR の Private Registry に docker push するので認証が必要です


```bash
make build
```

FARGATE_SPOT を利用できるように、意図的に `--platform linux/amd64` で docker build します


```bash
make tag
make push
```

`latest` タグを付加して、ECR へ `bastion:latest` イメージを push します



### Fargate に bastion-client をデプロイ

利用するときだけ ECS Task を run するように、desiredCount=0 で ecspresso deploy します

```bash
cd /path/to/deploy/ecspresso/live
```

```bash
direnv allow
```

```bash
make verify
```

```bash
make dry-deploy
```

```bash
make deploy
```


## もうちょっと

- [ ] ECS Exec 時のログを CloudWatch Logs に書き出せてないので出したい
    - check_login.sh が回っているので PID 1 が空いてなくて？

- [ ] ポートフォワードで、ローカルからGUIでのクライアントツールでの MySQL 接続ができるはず（たぶん） 
    - ecspresso でも「開通」できそう。 https://github.com/kayac/ecspresso?tab=readme-ov-file#port-forwarding 見た感じでは

- [ ] [utern](https://github.com/knqyf263/utern) (Multi group and stream log tailing for AWS CloudWatch Logs) との合わせ技で tail しながらオペレーションできると良さそう

- [ ] Terragrunt の CI


## その他

- live の下にもう１階層環境ごとのディレクトリを置くのが良いかも（階層調整は必要）
- ライセンスとか置く？
