# 만약 s3 파일을 불러오는데 문제가 생긴다면

aws s3api put-bucket-cors \
  --bucket your-bucket-name \
  --cors-configuration file://cors.json
