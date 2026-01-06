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
