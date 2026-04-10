## 使用场景

如果接口配置了**AK/SK**或**JWT**认证策略，您可以参考本文档生成认证头部`Authorization`，完成API的调用。

## 前置条件

- 已获取`AccessKey `和 `SecretKey`

- AK/SK认证策略：已知签名Header字段、签名算法、是否校验body等参数值

- JWT认证策略：已知token最大的过期时间

## SDK文件结构

下载SDK，解压api-signature-sdk-x.x.x.zip压缩包之后目录结构如下：

| 名称                                                         | 说明                 |
| ------------------------------------------------------------ | -------------------- |
| libs\                                                        | SDK依赖库            |
| libs\api-signature-sdk-x.x.x.jar                             | SDK包                |
| libs\api-signature-sdk-x.x.x-sources.jar.jar                 | SDK源码              |
| libs\commons-codec-1.11.jar<br/>libs\commons-logging-1.2.jar<br/>libs\httpclient-4.5.2.jar<br/>libs\httpcore-4.4.4.jar<br/>libs\jackson-annotations-2.9.0.jar<br/>libs\jackson-core-2.9.8.jar<br/>libs\jackson-databind-2.9.8.jar<br/>libs\java-jwt-3.7.0.jar | 相关依赖包           |
| src\AkSkDemo.java                                            | AKSK认证策略示例代码 |
| src\JwtDemo.java                                             | JWT认证策略示例代码  |
| README.md                                                    | 使用说明             |

您在导入以上依赖包至工程时，除了可以直接使用libs目录下提供的8个依赖jar包，您还可以通过下面的Gradle配置方式完成引入。

```
compile group: 'com.auth0', name: 'java-jwt', version: '3.7.0'
compile group: 'org.apache.httpcomponents', name: 'httpclient', version: '4.5.2'
```


## 使用示例

#### AKSK认证使用示例

##### 1、创建request，需要配置的参数如下

- signAlgorithm：签名算法，支持hmac-sha1，hmac-sha256，hmac-sha384及hmac-sha512
- accessKey：可在管理页面上获取
- secretKey：可在管理页面上获取
- validateBody：是否校验请求体，如果设置为true，请求体大小请不要超过8K
- requestHeaders：请求头部，`Date`头部（使用GMT格式）为必选
- enforceHeaders：客户应用于HTTP签名创建的header列表，请您确保header的顺序与配置一致
- request-line：http请求行，如果`enforceHeaders`里配置了`request-line`，请配置此参数（如： POST /demo HTTP/1.1）
- body：请求体，当请求体为空或者`validateBody`为false时，不用配置此参数

示例代码：

```java
private static Request initRequest() {
    Request request = new Request();

    request.setRequestLine("POST /demo HTTP/1.1");
    request.setBody("A small demo body");
    request.setSignAlgorithm(HMacSHA256SignerFactory.METHOD);
    request.setAccessKey("cloudos_demo_key");
    request.setSecretKey("cloudos_demo_secret");
    request.setValidateBody(true);

    // 必选header：Date, 且为 Greenwich Mean Time (GMT)标准时间
    SimpleDateFormat dateFormatGmt = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss z", Locale.ENGLISH);
    dateFormatGmt.setTimeZone(TimeZone.getTimeZone("GMT"));
    request.addHeader("Date", dateFormatGmt.format(new Date()));
    request.addHeader("Content-Type", "text/plain");

    // hmacHeaders请保证Header字段顺序正确
    request.addEnforceHeader("Date");
    request.addEnforceHeader("request-line");

    return request;
}
```

##### 2、对请求进行签名

```java
Map<String, String> httpHeaders = AkSkSign.sign(request);
```

使用AKSK的签名方法 `AkSkSign.sign(request)`生成认证头部`Authorization`。返回的头部`httpHeaders`由两部分组成：第一部分是创建request时配置的请求头部，第二部分为新生成的认证头部参数`Authorization`，如果开启了请求体认证且请求体不为空，则还会生成`Digest`头部。

生成的头部示例：

```yaml
Authorization: hmac username="cloudos_demo_key", algorithm="hmac-sha256", headers="Date request-line Digest", signature="ATHt54bpQ1pug8bDUlbbVouIksKily3Hm7IyamyiUMY="
Digest: SHA-256=H6+Kf4WXHO0vGU6J09qdHup1e9RchbAIrFuonAaDvsw=
Date: Thu, 21 May 2020 12:07:04 GMT
Content-Type: text/plain
```

##### 3、访问API

```java
HttpClient client = HttpClientBuilder.create().build();
String url = "http://10.125.30.111:28000/demo";
HttpPost httpPost = new HttpPost(url);
for (Map.Entry<String, String> entry : httpHeaders.entrySet()) {
    System.out.println(entry.getKey() +": "+ entry.getValue());
    httpPost.addHeader(entry.getKey(), entry.getValue());
}
if(null != request.getBody()) {
    ByteArrayEntity byteArrayEntity = new ByteArrayEntity(request.getBody().getBytes(StandardCharsets.UTF_8));
    httpPost.setEntity(byteArrayEntity);
}
HttpResponse response = client.execute(httpPost);
```

#### JWT认证使用示例

##### 1、 对请求进行签名

示例代码:

```java
String key = "cloudos_demo_key" ;
String secret = "cloudos_demo_secret";
// token过期时间timeToLiveSeconds应小于认证策略配置的最大过期时间
Integer timeToLiveSeconds = 1800;
String sign = JwtSign.sign(accessKey, secretKey, timeToLiveSeconds);
```

使用JWT的签名方法`JwtSign.sign(accessKey, secretKey, timeToLiveSeconds)`生成认证。

##### 2、访问API

```java
HttpClient client = HttpClientBuilder.create().build();
String url = "http://10.125.30.111:28000/demo";
HttpGet httpGet = new HttpGet(url);
httpGet.addHeader("Authorization", sign);
HttpResponse response = client.execute(httpGet);
```

将第1步生成的字符串配置到请求的认证头部中，完成接口的调用。