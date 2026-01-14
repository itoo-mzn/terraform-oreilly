variable "server_port" {
  description = "HTTPリクエストを受け付けるポート番号"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description = "クラスター名（リソースのprefixなどに使用）"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "DBのステート管理をしているS3バケット名"
  type        = string
}

variable "db_remote_state_key" {
  description = "DBのステート管理をしているファイルパス（S3バケット内）"
  type        = string
}

variable "instance_type" {
  description = "EC2インスタンスタイプ（例：t2.micro）"
  type        = string
}

variable "min_size" {
  description = "オートスケーリンググループの最小インスタンス数"
  type        = number
}

variable "max_size" {
  description = "オートスケーリンググループの最大インスタンス数"
  type        = number
}

variable "custom_tags" {
  description = "インスタンス用オートスケーリンググループへのタグ"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "オートスケーリングを有効にするかどうか"
  type        = bool
  default     = false
}
