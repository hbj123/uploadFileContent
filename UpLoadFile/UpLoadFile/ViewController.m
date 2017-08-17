//
//  ViewController.m
//  UploadFile
//
//  Created by hbj on 2017/8/17.
//  Copyright © 2017年 宝剑. All rights reserved.
//
/*post有两种上传方式，这里只列举上传附件的方式(这种请求方式支持文件或文件&普通参数或普通参数)即：
 Content-Type = multipart/form-data;
 该种类型有固定的参数拼接格式
 普通参数
 --boundry\r\n
 Content-Disposition: form-data; name=\"%@\"\r\n
 \r\n
 value
 \r\n
 文件参数
 --boundry\r\n
 Content-Disposition:form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n
 \r\n
 data
 \r\n
 参数结尾
 --boundry--\r\n
 其中
 name 即为表单请求字段(服务端要的参数字段),fileName为保存在服务端的文件名字,Content-Type为文件类型(image/png 或者video/mpeg4等等)，具体可以查看Content-Type参照表
 这里着重说下即使服务端要参数是int类型，这里也必须普通参数也必须是字符串对象
 文件上传的地址为:http://主机名称:端口/应用名称/upload.action,文件的域名称为risenUpload,另外可以带一个参数savePath表示
 例如savePath=/aaa/bbb/通知2014-10-10.png
 */

#import "ViewController.h"
//文件上传地址
#define KUpdateFileURL @"http://114.215.207.239:8083/upload/upload.action"
#define TEST_FORM_BOUNDARY @"AaB03x"
#define BMEncode(str) [str dataUsingEncoding:NSUTF8StringEncoding]
#define kLog(str)  NSLog(@"%@%d%s%s", str, __LINE__, __func__, __TIME__)

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)clickUploadAction:(UIButton *)sender {
    
    [self uploadBtnTitle:@"正在上传"];
    /*获取图片数据*/
    UIImage *image = [UIImage imageNamed:@"uploadPhoto.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    
    /*生成唯一的文件名*/
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [self uuidString]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMddHHmmss"];
    /*将当前时间转化为时间戳*/
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    
    //传入的参数集合
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:imageData, @"file", fileName, @"fileName", timeString, @"fileTime", nil];
    [self uploadFile:KUpdateFileURL parames:settings];
    
}

/*上传文件  url上传地址   parames上传参数*/
- (void)uploadFile:(NSString *)url parames:(NSDictionary *)parames {
    [self executeSessionTask:[self executeAppendParam:url parames:parames]];
}


- (NSMutableURLRequest *)executeAppendParam:(NSString *)url parames:(NSDictionary *)parames {
    NSMutableString *mutableString = [NSMutableString new];
    NSMutableData *bodyData = [NSMutableData new];
    //1.普通参数
    NSString *startString = [NSString stringWithFormat:@"--%@\r\n", TEST_FORM_BOUNDARY];
    [mutableString appendString:startString];
    NSString *generalContent = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", @"savePath"];
    [mutableString appendString:generalContent];
    [mutableString appendString:@"\r\n"];
    NSString *generalValue = [NSString stringWithFormat:@"/%@/%@", [parames valueForKey:@"fileTime"], [parames valueForKey:@"fileName"]];
    [mutableString appendString:generalValue];
    [mutableString appendString:@"\r\n"];

    //1.文件参数
    [mutableString appendString:startString];
    //    NSString *fileContent = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"risenUpload\";filename=\"%@\"\r\n", [parames valueForKey:@"fileName"]];
    //[mutableString appendString:fileContent];
    [mutableString appendFormat:@"%@", [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"risenUpload\"; filename=\"%@\"\r\n",[parames valueForKey:@"fileName"]]];
    NSString *contentType = @"Content-Type:application/octet-stream\r\n";
    [mutableString appendString:contentType];
    [mutableString appendString:@"\r\n"];
    [bodyData appendData:BMEncode(mutableString)];
    [bodyData appendData:[parames valueForKey:@"file"]];
    [bodyData appendData:BMEncode(@"\r\n")];
    NSString *endString = [NSString stringWithFormat:@"--%@--\r\n", TEST_FORM_BOUNDARY];
    [bodyData appendData:BMEncode(endString)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:1000];
    
    //设置上传数据的长度及格式
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",TEST_FORM_BOUNDARY]forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u",(unsigned)bodyData.length]forHTTPHeaderField:@"Content-Length"];
    [request addValue:[self IDFAString] forHTTPHeaderField:@"client"];
    //设置请求类型
    [request setHTTPMethod:@"POST"];
    //请求参数体
    [request setHTTPBody:bodyData];
    kLog(@"测试");
    return request;
}

- (void)executeSessionTask:(NSMutableURLRequest *)request {
    //创建会话
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:nil completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        kLog(@"测试");
        if (!error) {
            NSLog(@"response:%@",response);
            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"dataStr:%@",dataStr);
            [self uploadBtnTitle:@"上传成功"];
        }else{
            NSLog(@"error:%@",error);
            [self uploadBtnTitle:@"上传失败"];
        }
    }];
    [uploadTask resume];
    kLog(@"测试");
}


- (void)uploadBtnTitle:(NSString *)title{
    [self.uploadBtn setTitle:title forState:UIControlStateNormal];
}

//快速格式化代码  ctrl+i
- (NSString *)uuidString {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}

- (NSString *)IDFAString
{
    NSString * str = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return  str;
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
