---
layout: post
title: 微信新版支付(V3.3.6)  问题清单
categories: 在线支付
description: 微信新版支付(V3.3.6)问题清单
keywords: 微信开发,微信支付,在线支付
---



# 确保 商户功能 审核通过，会有官方邮件
# 支付授权目录（注意看文档，大小写关系很大 点击支付按钮，提示“access_denied” 网上有很多关于此问题的解决）
# 点击支付按钮，提示“access_not_allow” 需要将测试人的微信帐号加入白名单
#【在开发调试阶段，测试链接需要在公众号内点击打开 白名单用户在公众号内向公众号发一条消息，消息内容即为测试链接，然后点击打开】文档中写得很清楚，但中招的人还是不计其数（偶也中了……）。
#【参数大小写敏感】md5 运算后，字符串的字符要转换为大写，注意是MD5运算模块。
# 利用JSAPI 支付，提示“该公众号支付签名无效，无法发起该笔交易


```js            
        function getAppId() {
            return $("#appId").val();
        }        
        function getSignType() {
            return "MD5";
        }
        function getPackage() {
            return "prepay_id=" + $("#prepay_id").val();
        }
        var signString;
        function getSign() {
            signString = "appId=" + getAppId() + "&nonceStr=" + $("#nonceStr").val() + "&package=" + getPackage() + "&signType=" + getSignType() + "&timeStamp=" + getTimeStamp() + "&key=" + getKey();
        return CryptoJS.MD5(signString).toString().toUpperCase(); 
    }
    
$("#getBrandWCPayRequest").bind("click",function{
try{
alert("Package的值:"+getPackage());
alert("Sign的值:"+getSign());
alert("Sign加密的值:"+signString);
WeixinJSBridge.invoke('getBrandWCPayReqeust',{
    "appId":getAppid(),//公众号名称,由商户传入
    "timeStamp":getTimeStamp(),//时间戳
    "nonceStr":getNonceStr(),//随机串
    "package":getPackage(),//扩展包
    "signType":getSignType(),//微信前面方式:1.MD5
    "paySign":getSign()//微信签名
},function(res){
    alert(ret[0]+ret[1]);
    if(res.err_msg=="get_brand_wcpay_request:ok"){
        alert("成功");
    }  else
    {
        alert("失败");
    }
    //使用以上方式判断前端返回,微信团队郑重提示:res.err_msg将在用户支付成功后返回ok,但并不保证它绝对可靠.
    //因此微信团队建议,当收到ok返回时,向商户后台询问是否收到交易成功通知,若收到通知,前端展示交易成功的界面;若此时未收到通知,商户后台主动
    //调用
})


}catch(e){
alert(e);
}
})　　　　
```
# 屏蔽含有mall的域名以及含有阿里的域名
问题”测试目录改为http://mall.xxx.com/后，网页支付时直接提示get_brand_wcpay_request:fail_invalid appid 。
使用了其他的目录如http://store.xxx.com/ 也毫无问题。估计微信内部把含mall的支付都给屏蔽了。 “ 此问题还没亲自验证，
不过在微信中还是请不要用关于阿里有关的域名，否则都不知道怎么坑死的。      
