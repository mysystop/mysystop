---
layout: post
title: 如何使用Golang来处理支付宝的回调
categories: 在线支付
description: 如何使用Golang来处理支付宝的回调
keywords: 支付宝开发,支付宝支付,golang支付宝支付,在线支付
---
# Golang处理支付宝的回调

支付宝的回调还是有蛮多坑的，当时我也搞了几天才算彻底的把这个问题搞定。 
现在记录一下，以备忘。

1. 支付宝的处理流程 
![支付宝的处理流程](/images/posts/pay/alipay/alipay-process.png) 

2. 上述图中第五步，异步发送支付通知“商户服务端”这里就是我们后台服务器需要处理的流程。 
3. 处理流程其实很简单，但是需要注意的是，支付宝的文档中写的是“在参数列表“里带入这些参数。

以下这段示例代码来自于支付宝的官方文档：
```url
http://notify.java.jpxx.org/index.jsp?discount=0.00&payment_type=1&subject=测试&trade_no=2013082244524842&buyer_email=dlwdgl@gmail.com&gmt_create=2013-08-22 14:45:23&notify_type=trade_status_sync&quantity=1&out_trade_no=082215222612710&seller_id=2088501624816263&notify_time=2013-08-22 14:45:24&body=测试测试&trade_status=TRADE_SUCCESS&is_total_fee_adjust=N&total_fee=1.00&gmt_payment=2013-08-22 14:45:24&seller_email=xxx@alipay.com&price=1.00&buyer_id=2088602315385429&notify_id=64ce1b6ab92d00ede0ee56ade98fdf2f4c&use_coupon=N&sign_type=RSA&sign=1glihU9DPWee+UJ82u3+mw3Bdnr9u01at0M/xJnPsGuHh+JA5bk3zbWaoWhU6GmLab3dIM4JNdktTcEUI9/FBGhgfLO39BKX/eBCFQ3bXAmIZn4l26fiwoO613BptT44GTEtnPiQ6+tnLsGlVSrFZaLB9FVhrGfipH2SWJcnwYs=
```
但是这里有个巨大的错误，因为他的参数实际上并不是在HTTP Request的参数部分，而是在HTTP Body部分，这里要特别注意。

4. 如何处理支付宝的签名，这个签名是用来验证请求的有效性，官方文档里有指明此签名用RSA算法进行签名。但是这个签名是怎么来的，实际上还经过了好几个步骤：

 1. 对参数[key,value]按照key进行排序
 2. 按照key1=value1&key2=value2...的顺序进行用&和=进行连接，但是不包含'sign'和‘sign_type’
 3. 然后用SHA1进行计算摘要
 4. 进行标准base64的编码
 5. URL Safe Encoding
以上黑色部分，也就是3，4这里是特别需要注意的。 
所以验证这个签名的有效性我们就可以这样做，我把步骤写在下面：

a. 我们首先从HTTP body中读入参数字符串。
```go
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        return
    }
    //此时body就是支付宝给我们的参数字符串
```
 b. 然后使用url包的ParseQuery取得参数
 ```go
    values_m, _err := url.ParseQuery(string(paramerStr))//values_m就是我们的参数了
    if _err != nil {
        fmt.Println("error parse parameter, reason:", _err)
        return
    }
```
c.把参数按照key的字母顺序升序排列，然后使用=连接key和value,使用&连接其余key,value,不包含'sign'和'sign_type'，假设得到的字串为preSignString.

d.对上面preSignString进行SHA1哈希：
```go
    t := sha1.New()
    io.WriteString(t, string(preSignString))
    digest := t.Sum(nil)
```
e.从支付宝给我们的参数列表中parse出来签名
```go
    sign := values_m["sign"][0]
```
f.对支付宝的签名进行Std base64 decode,URL decode已经不需要了，url.ParseQuery已经进行过了urldecode.
```go
    data, _ := base64.StdEncoding.DecodeString(string(sign))
```
g.调用rsa包的VerifyPKCS1v15进行签名验证。传入参数为我们计算出来的preSignString的哈希digest,哈希算法crypto.SHA1，以及支付宝的公钥，还有f步骤的data. 这个data是先进行过url decode然后又进行过std base64decode过的数据。
```go
    err = rsa.VerifyPKCS1v15(rsaPub, crypto.SHA1, digest, data)
    if err != nil {
        fmt.Println("Verify sig error, reason: ", err)
        return false, err
    }
```
完整的程序如下，经过调试可以正常验证签名。当然签名验证通过之后的步骤我就不多说了，比如记录自己的数据库，比如通知客户端刷新取得状态等等，大家可以自行补充。
```go
package main

import (
    "crypto"
    "crypto/rsa"
    "crypto/sha1"
    "crypto/x509"
    "encoding/base64"
    "encoding/hex"
    "encoding/pem"
    "fmt"
    "io"
    "net/url"
    "sort"
)

const (
    //支付宝公钥
    ALIPAY_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----  
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCnxj/9qwVfgoUh/y2W89L6BkRA
FljhNhgPdyPuBV64bfQNN1PjbCzkIM6qRdKBoLPXmKKMiFYnkd6rAoprih3/PrQE
B/VsW8OoM8fxn67UDYuyBTqA23MML9q1+ilIZwBC2AQ2UBVOrFXfFl75p6/B5Ksi
NG9zpgmLCUYuLkxpLQIDAQAB 
-----END PUBLIC KEY-----
`
)

func main() {
    //这是我从支付宝callback的http body部分读取出来的一段参数列表。
    paramerStr := `discount=0.00&payment_type=1&subject=%E7%BC%B4%E7%BA%B3%E4%BF%9D%E8%AF%81%E9%87%91&trade_no=2015122121001004460085270336&buyer_email=xxaqch%40163.com&gmt_create=2015-12-21+13%3A13%3A28&notify_type=trade_status_sync&quantity=1&out_trade_no=a378c684be7a4f99be1bf3b56e6d38fd&seller_id=2088121529348920&notify_time=2015-12-21+13%3A17%3A45&body=%E7%BC%B4%E7%BA%B3%E4%BF%9D%E8%AF%81%E9%87%91&trade_status=TRADE_SUCCESS&is_total_fee_adjust=N&total_fee=0.01&gmt_payment=2015-12-21+13%3A13%3A28&seller_email=172886370%40qq.com&price=0.01&buyer_id=2088002578894463&notify_id=5104b719303162e2b79d577aeaa5494jjs&use_coupon=N&sign_type=RSA&sign=YeshUpQO1GsR4KxQtAlPzdlqKUMlTfEunQmwmNI%2BMJ1T2qzd9WuA6bkoHYMM8BpHxtp5mnFM3rXlfgETVsQcNIiqwCCn1401J%2FubOkLi2O%2Fmta2KLxUcmssQ0OnkFIMjjNQuU9N3eIC1Z6SzDkocK092w%2Ff3un4bxkIfILgdRr0%3D`

    //调用url.ParseQuery来获取到参数列表，url.ParseQuery还会自动做url safe decode
    values_m, _err := url.ParseQuery(string(paramerStr))
    if _err != nil {
        fmt.Println("error parse parameter, reason:", _err)
        return
    }
    var m map[string]interface{}
    m = make(map[string]interface{}, 0)

    for k, v := range values_m {
        if k == "sign" || k == "sign_type" { //不要'sign'和'sign_type'
            continue
        }
        m[k] = v[0]
    }

    sign := values_m["sign"][0]
    fmt.Println("Parsed Sign:", []byte(sign))

    //获取要进行计算哈希的sign string
    strPreSign, _err := genAlipaySignString(m)
    if _err != nil {
        fmt.Println("error get sign string, reason:", _err)
        return
    }

    fmt.Println("Presign string:", strPreSign)

    //进行rsa verify
    pass, _err := RSAVerify([]byte(strPreSign), []byte(sign))

    if pass {
        fmt.Println("verify sig pass.")
    } else {
        fmt.Println("verify sig not pass. error:", _err)
    }
}
/***************************************************************
*函数目的：获得从参数列表拼接而成的待签名字符串
*mapBody：是我们从HTTP request body parse出来的参数的一个map
*返回值：sign是拼接好排序后的待签名字串。
***************************************************************/
func genAlipaySignString(mapBody map[string]interface{}) (sign string, err error) {
    sorted_keys := make([]string, 0)
    for k, _ := range mapBody {
        sorted_keys = append(sorted_keys, k)
    }
    sort.Strings(sorted_keys)
    var signStrings string

    index := 0
    for _, k := range sorted_keys {
        fmt.Println("k=", k, "v =", mapBody[k])
        value := fmt.Sprintf("%v", mapBody[k])
        if value != "" {
            signStrings = signStrings + k + "=" + value
        }
        //最后一项后面不要&
        if index < len(sorted_keys)-1 {
            signStrings = signStrings + "&"
        }
        index++
    }

    return signStrings, nil
}

/***************************************************************
*RSA签名验证
*src:待验证的字串，sign:支付宝返回的签名
*pass:返回true表示验证通过
*err :当pass返回false时，err是出错的原因
****************************************************************/
func RSAVerify(src []byte, sign []byte) (pass bool, err error) {
    //步骤1，加载RSA的公钥
    block, _ := pem.Decode([]byte(ALIPAY_PUBLIC_KEY))
    pub, err := x509.ParsePKIXPublicKey(block.Bytes)
    if err != nil {
        fmt.Printf("Failed to parse RSA public key: %s\n", err)
        return
    }
    rsaPub, _ := pub.(*rsa.PublicKey)

    //步骤2，计算代签名字串的SHA1哈希
    t := sha1.New()
    io.WriteString(t, string(src))
    digest := t.Sum(nil)

    //步骤3，base64 decode,必须步骤，支付宝对返回的签名做过base64 encode必须要反过来decode才能通过验证
    data, _ := base64.StdEncoding.DecodeString(string(sign))

    hexSig := hex.EncodeToString(data)
    fmt.Printf("base decoder: %v, %v\n", string(sign), hexSig)

    //步骤4，调用rsa包的VerifyPKCS1v15验证签名有效性
    err = rsa.VerifyPKCS1v15(rsaPub, crypto.SHA1, digest, data)
    if err != nil {
        fmt.Println("Verify sig error, reason: ", err)
        return false, err
    }

    return true, nil
}
```