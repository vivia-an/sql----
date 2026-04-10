import com.h3c.core.api.sdk.model.Request;
import com.h3c.core.api.sdk.signature.HMacSHA256SignerFactory;
import com.h3c.core.api.sdk.util.AkSkSign;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ByteArrayEntity;
import org.apache.http.impl.client.HttpClientBuilder;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

public class AkSkDemo {
    public static void main(String[] args) throws Exception {

        Request request = initRequest();
        Map<String, String> httpHeaders = AkSkSign.sign(request);

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
        System.out.println("status code: " + response.getStatusLine().getStatusCode());
        BufferedReader rd = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
        StringBuilder result = new StringBuilder();
        String line;
        while ((line = rd.readLine()) != null) {
            result.append(line);
        }
        System.out.println("response: " + result);
    }

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

}
