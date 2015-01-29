# Weixin JS-SDK Sample

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Demo

Start the server, then open website from Weixin/Wechat.

## Fetch a signature

```shell
curl "http://example.com/signature" \
  -X "POST" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d $'{
  "nonce_str": "Wm3WZYTPz0wzccnW",
  "timestamp": "1414587457",
  "url": "http://mp.weixin.qq.com"
}'
```

Returns

```json
{
  "signature": "0f9de62fce790f9a083d5c99e95740ceb90c27ed"
}
```
