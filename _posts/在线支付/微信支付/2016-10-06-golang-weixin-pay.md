---
layout: post
title: 如何使用golang实现微信支付的服务端
categories: 在线支付
description: 如何使用golang实现微信支付的服务端
keywords: 微信开发,微信支付,golang微信支付,在线支付
---
一般来说，使用golang主要还是写服务端。所以本文主要讲golang在处理微信移动支付的服务端时的统一下单接口和支付回调接口，以及查询接口。

# 微信支付流程

下图是微信官网的支付流程描述： 

![微信支付流程](/images/posts/pay/weixinpay/weixin-pay-golang-process.png)


图中红色部分就是微信支付中，我们的系统包括app,后台需要参与的流程。 
其中需要后台也就是Server需要参与的流程有三个： 
1. 统一下单并返回客户端 
2. 异步通知结果回调处理 
3. 调用微信支付查询接口

微信所有的接口都是以http RESTFul的API来提供，所以对于server而言其实就是call这些接口并处理返回值。

# 调用统一下单接口

首先需要呼叫：[https://api.mch.weixin.qq.com/pay/unifiedorder][1] 这是微信的api,呼叫之后微信会返回我们一个prepay_id。调用的结果以微信正确的返回给我们prepay id为准。

按照微信文档说明，这个接口的参数没有，我们传入的参数需要以xml的形式来写入http request的body部分传给微信。

需要注意的问题有两点，第一个是sign的计算，另一个是golang中xml包很坑，没有提供DOM方式操作xml的接口，marshal后的字串需要手工修改以达到满足微信要求的这种根节点的格式。

```go
//首先定义一个UnifyOrderReq用于填入我们要传入的参数。
type UnifyOrderReq struct {
    Appid            string `xml:"appid"`
    Body             string `xml:"body"`
    Mch_id           string `xml:"mch_id"`
    Nonce_str        string `xml:"nonce_str"`
    Notify_url       string `xml:"notify_url"`
    Trade_type       string `xml:"trade_type"`
    Spbill_create_ip string `xml:"spbill_create_ip"`
    Total_fee        int    `xml:"total_fee"`
    Out_trade_no     string `xml:"out_trade_no"`
    Sign             string `xml:"sign"`
}

//微信支付计算签名的函数
func wxpayCalcSign(mReq map[string]interface{}, key string) (sign string) {
    fmt.Println("微信支付签名计算, API KEY:", key)
    //STEP 1, 对key进行升序排序.
    sorted_keys := make([]string, 0)
    for k, _ := range mReq {
        sorted_keys = append(sorted_keys, k)
    }

    sort.Strings(sorted_keys)

    //STEP2, 对key=value的键值对用&连接起来，略过空值
    var signStrings string
    for _, k := range sorted_keys {
        fmt.Printf("k=%v, v=%v\n", k, mReq[k])
        value := fmt.Sprintf("%v", mReq[k])
        if value != "" {
            signStrings = signStrings + k + "=" + value + "&"
        }
    }

    //STEP3, 在键值对的最后加上key=API_KEY
    if key != "" {
        signStrings = signStrings + "key=" + key
    }

    //STEP4, 进行MD5签名并且将所有字符转为大写.
    md5Ctx := md5.New()
    md5Ctx.Write([]byte(signStrings))
    cipherStr := md5Ctx.Sum(nil)
    upperSign := strings.ToUpper(hex.EncodeToString(cipherStr))
    return upperSign
}
```
统一下单接口调用的范例：

```go
//请求UnifiedOrder的代码
    var yourReq UnifyOrderReq
    yourReq.Appid = "app_id" //微信开放平台我们创建出来的app的app id
    yourReq.Body = "商品名"
    yourReq.Mch_id = "商户编号"
    yourReq.Nonce_str = "your nonce"
    yourReq.Notify_url = "www.yourserver.com/wxpayNotify"
    yourReq.Trade_type = "APP"
    yourReq.Spbill_create_ip = "xxx.xxx.xxx.xxx"
    yourReq.Total_fee = 10 //单位是分，这里是1毛钱
    yourReq.Out_trade_no = "后台系统单号"

    var m map[string]interface{}
    m = make(map[string]interface{}, 0)
    m["appid"] = yourReq.Appid
    m["body"] = yourReq.Body
    m["mch_id"] = yourReq.Mch_id
    m["notify_url"] = yourReq.Notify_url
    m["trade_type"] = yourReq.Trade_type
    m["spbill_create_ip"] = yourReq.Spbill_create_ip
    m["total_fee"] = yourReq.Total_fee
    m["out_trade_no"] = yourReq.Out_trade_no
    m["nonce_str"] = yourReq.Nonce_str
    yourReq.Sign = wxpayCalcSign(m, "wxpay_api_key") //这个是计算wxpay签名的函数上面已贴出

    bytes_req, err := xml.Marshal(yourReq)
    if err != nil {
        fmt.Println("以xml形式编码发送错误, 原因:", err)
        return
    }

    str_req := string(bytes_req)
    //wxpay的unifiedorder接口需要http body中xmldoc的根节点是<xml></xml>这种，所以这里需要replace一下
    str_req = strings.Replace(str_req, "UnifyOrderReq", "xml", -1)
    bytes_req = []byte(str_req)

    //发送unified order请求.
    req, err := http.NewRequest("POST", unify_order_req, bytes.NewReader(bytes_req))
    if err != nil {
        fmt.Println("New Http Request发生错误，原因:", err)
        return
    }
    req.Header.Set("Accept", "application/xml")
    //这里的http header的设置是必须设置的.
    req.Header.Set("Content-Type", "application/xml;charset=utf-8")

    c := http.Client{}
    resp, _err := c.Do(req)
    if _err != nil {
        fmt.Println("请求微信支付统一下单接口发送错误, 原因:", _err)
        return
    }

    //到这里统一下单接口就已经执行完成了
```
接下来就是微信统一下单接口的响应，首先定义解析微信返回的response的数据结构。
然后就是标准的http response的处理流程。
其中我们需要使用的主要还是他的prepay id,拿到prepay id，服务端需完成的支付流程就基本完毕，将prepay id给客户端继续支付流程。
```go
type UnifyOrderResp struct {
        Return_code string `xml:"return_code"`
        Return_msg  string `xml:"return_msg"`
        Appid       string `xml:"appid"`
        Mch_id      string `xml:"mch_id"`
        Nonce_str   string `xml:"nonce_str"`
        Sign        string `xml:"sign"`
        Result_code string `xml:"result_code"`
        Prepay_id   string `xml:"prepay_id"`
        Trade_type  string `xml:"trade_type"`
    }

    xmlResp := UnifyOrderResp{}
    _err = xml.Unmarshal(body, &xmlResp)
    //处理return code.
    if xmlresp.Return_code == "FAIL" {
        fmt.Println("微信支付统一下单不成功，原因:", xmlresp.Return_msg)
        return
    }

    //这里已经得到微信支付的prepay id，需要返给客户端，由客户端继续完成支付流程
    fmt.Println("微信支付统一下单成功，预支付单号:", xmlResp.Prepay_id)
```
# 微信异步通知的处理

在微信支付的流程图中，当客户端支付完成以后，微信会异步的来通知商户后台系统对支付结果进行一次更新，或更新数据库，或通知客户端，根据你的业务来定。 
回调函数实际上就是我们在第一步统一下单接口里设置的回调函数。

```go
yourReq.Notify_url = "www.yourserver.com/wxpayNotify"
```

就是这里设置的这个地址，这个地址指向我们后台的一个接口(其他语言就是页面），当支付的结果变化时，微信会异步来透过这个接口通知我们支付的结果。

在处理上，主要是针对他的签名的一个检查。在有了第一步计算签名函数wxpayCalcSign的基础上这个签名检查就很简单了，直接针对微信异步通知的请求，计算一次签名(不含他请求的签名，不含空串)，然后比对微信返回的签名和他的异步通知的签名是否是一致的就可以。

微信异步通知的数据结构，他也是以xml形式包含在请求的body中，解出来即可。

```go
type WXPayNotifyReq struct {
    Return_code    string `xml:"return_code"`
    Return_msg     string `xml:"return_msg"`
    Appid          string `xml:"appid"`
    Mch_id         string `xml:"mch_id"`
    Nonce          string `xml:"nonce_str"`
    Sign           string `xml:"sign"`
    Result_code    string `xml:"result_code"`
    Openid         string `xml:"openid"`
    Is_subscribe   string `xml:"is_subscribe"`
    Trade_type     string `xml:"trade_type"`
    Bank_type      string `xml:"bank_type"`
    Total_fee      int    `xml:"total_fee"`
    Fee_type       string `xml:"fee_type"`
    Cash_fee       int    `xml:"cash_fee"`
    Cash_fee_Type  string `xml:"cash_fee_type"`
    Transaction_id string `xml:"transaction_id"`
    Out_trade_no   string `xml:"out_trade_no"`
    Attach         string `xml:"attach"`
    Time_end       string `xml:"time_end"`
}

type WXPayNotifyResp struct {
    Return_code string `xml:"return_code"`
    Return_msg  string `xml:"return_msg"`
}

//具体的微信支付回调函数的范例
func WxpayCallback(w http.ResponseWriter, r *http.Request) {
    // body
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        fmt.Println("读取http body失败，原因!", err)
        http.Error(w.(http.ResponseWriter), http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
        return
    }
    defer r.Body.Close()

    fmt.Println("微信支付异步通知，HTTP Body:", string(body))
    var mr WXPayNotifyReq
    err = xml.Unmarshal(body, &mr)
    if err != nil {
        fmt.Println("解析HTTP Body格式到xml失败，原因!", err)
        http.Error(w.(http.ResponseWriter), http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
        return
    }

    var reqMap map[string]interface{}
    reqMap = make(map[string]interface{}, 0)

    reqMap["return_code"] = mr.Return_code
    reqMap["return_msg"] = mr.Return_msg
    reqMap["appid"] = mr.Appid
    reqMap["mch_id"] = mr.Mch_id
    reqMap["nonce_str"] = mr.Nonce
    reqMap["result_code"] = mr.Result_code
    reqMap["openid"] = mr.Openid
    reqMap["is_subscribe"] = mr.Is_subscribe
    reqMap["trade_type"] = mr.Trade_type
    reqMap["bank_type"] = mr.Bank_type
    reqMap["total_fee"] = mr.Total_fee
    reqMap["fee_type"] = mr.Fee_type
    reqMap["cash_fee"] = mr.Cash_fee
    reqMap["cash_fee_type"] = mr.Cash_fee_Type
    reqMap["transaction_id"] = mr.Transaction_id
    reqMap["out_trade_no"] = mr.Out_trade_no
    reqMap["attach"] = mr.Attach
    reqMap["time_end"] = mr.Time_end

    var resp WXPayNotifyResp
    //进行签名校验
    if wxpayVerifySign(reqMap, mr.Sign) {
        //这里就可以更新我们的后台数据库了，其他业务逻辑同理。
        resp.Return_code = "SUCCESS"
        resp.Return_msg = "OK"
    } else {
        resp.Return_code = "FAIL"
        resp.Return_msg = "failed to verify sign, please retry!"
    }

    //结果返回，微信要求如果成功需要返回return_code "SUCCESS"
    bytes, _err := xml.Marshal(resp)
    strResp := strings.Replace(string(bytes), "WXPayNotifyResp", "xml", -1)
    if _err != nil {
        fmt.Println("xml编码失败，原因：", _err)
        http.Error(w.(http.ResponseWriter), http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
        return
    }

    w.(http.ResponseWriter).WriteHeader(http.StatusOK)
    fmt.Fprint(w.(http.ResponseWriter), strResp)
}
```
微信签名验证函数，先针对微信回调的参数不含sign,做一次签名，api_key就是商户平台的api key。然后再比对通过我们的签名计算函数wxpayCalcSign和微信异步通知的签名是否是一致的就可以了。
```go
//微信支付签名验证函数
func wxpayVerifySign(needVerifyM map[string]interface{}, sign string) bool {
    signCalc := wxpayCalcSign(needVerifyM , "API_KEY")

    slog.Debug("计算出来的sign: %v", signCalc)
    slog.Debug("微信异步通知sign: %v", sign)
    if sign == signCalc {
        fmt.Println("签名校验通过!")
        return true
    }

    fmt.Println("签名校验失败!")
    return false
}
```
# 客户端查询订单请求响应

因微信端并不能保证异步通知是一定送达商户服务端，因此这里需要进行主动查询订单状态。 
[https://api.mch.weixin.qq.com/pay/orderquery][2] 这里是微信的查询接口。 
当然访问这个接口也很简单，将我们的系统单号，第一步的out_trade_no用作查询条件传入即可查到订单的当前状态。

签名依旧使用我们之前的签名计算函数来完成即可。

代码此处略过，没啥好讲的。

# 后记

这里只是一个golang的例子，不过其他语言和平台应该是类似的。 
例子中基本上传入的参数，需要替换为您对应的正确的参数就可以。 
范例中只包含于微信支付服务端沟通的API调用部分，商户平台因为各自不同业务逻辑我就省略了。


[1]: https://api.mch.weixin.qq.com/pay/unifiedorder
[2]: https://api.mch.weixin.qq.com/pay/orderquery 