import com.h3c.core.api.sdk.util.JwtSign;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.HttpClientBuilder;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class JwtDemo {
    public static void main(String[] args) throws Exception {
        String accessKey = "cloudos_demo_key" ;
        String secretKey = "cloudos_demo_secret";
        // token过期时间timeToLiveSeconds应小于认证策略配置的最大过期时间
        Integer timeToLiveSeconds = 1800;
        String sign = JwtSign.sign(accessKey, secretKey, timeToLiveSeconds);
        System.out.println("Authorization: " + sign);

        HttpClient client = HttpClientBuilder.create().build();
        String url = "http://10.125.30.111:28000/demo";
        HttpGet httpGet = new HttpGet(url);
        httpGet.addHeader("Authorization", sign);
        HttpResponse response = client.execute(httpGet);
        System.out.println("status code: " + response.getStatusLine().getStatusCode());
        BufferedReader rd = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
        StringBuilder result = new StringBuilder();
        String line;
        while ((line = rd.readLine()) != null) {
            result.append(line);
        }
        System.out.println("response: " + result);
    }
}
