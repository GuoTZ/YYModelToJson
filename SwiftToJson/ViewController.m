//
//  ViewController.m
//  SwiftToJson
//
//  Created by RM on 2018/4/10.
//  Copyright © 2018年 GTZ. All rights reserved.
//

#import "ViewController.h"

@interface MyType : NSObject
@property (nonatomic, copy  ) NSString *Nmae;
@property (nonatomic, strong) NSMutableArray <NSDictionary *>*List;
@end
@implementation MyType


@end
@interface ViewController ()

@property (weak) IBOutlet NSTextField *jsonTF;
@property (weak) IBOutlet NSTextField *prefixTf;
@property (nonatomic, strong) NSMutableArray <MyType *> *implementationArray;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"生成Swift对象";
    self.implementationArray = [NSMutableArray array];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)okJsonAction:(id)sender {
    if (self.jsonTF.stringValue.length==0) {
        [self alertMsg:@"请输入要转换的json"];
        return;
    }
    NSString *prefix = self.prefixTf.stringValue.length ? self.prefixTf.stringValue : @"";
    NSString *str = [NSString stringWithFormat:@"@interface %@Model : NSObject\n",prefix];
    NSString *json = [[self.jsonTF.stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@""]stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * firstChar = [json substringWithRange:NSMakeRange(0, 1)];
    self.jsonTF.stringValue = @"";
    if([firstChar isEqualToString:@"{"]){
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&err];
        str = [NSString stringWithFormat:@"%@%@",str,[self configDictionary:dict name:[NSString stringWithFormat:@"%@Model",prefix]]];
    }else{
        [self alertMsg:@"抱歉，目前只支持以‘{’开头的json"];
    }
    self.jsonTF.stringValue = [NSString stringWithFormat:@"%@\n\n%@@end",self.jsonTF.stringValue,str];
    
    NSString *implementationStr = @"";
    for (MyType *type in self.implementationArray) {
        implementationStr = [NSString stringWithFormat:@"%@\n\n@implementation %@",implementationStr,type.Nmae];
        
        if (type.List.count>0) {
            NSString *str1 = @"+(NSDictionary *)modelContainerPropertyGenericClass {\nreturn @{";
            implementationStr = [NSString stringWithFormat:@"%@\n %@",implementationStr,str1];
            
            for (NSDictionary *dict in type.List) {
                NSString *ID = dict[@"id"];
                if ([ID isEqualToString:@"1"]) {
                    NSString *str = [NSString stringWithFormat:@"@\"%@\":%@.class",[dict objectForKey:@"name"],[dict objectForKey:@"class"]];
                    implementationStr = [NSString stringWithFormat:@"%@\n %@",implementationStr,str];
                } else {
                    NSString *str = [NSString stringWithFormat:@"@\"%@\":[%@ class]",[dict objectForKey:@"name"],[dict objectForKey:@"class"]];
                    implementationStr = [NSString stringWithFormat:@"%@\n %@",implementationStr,str];
                }
            }
            
            
            
            NSString *str2 = @"};\n}";
            implementationStr = [NSString stringWithFormat:@"%@\n %@",implementationStr,str2];
            
        }
    
        implementationStr = [NSString stringWithFormat:@"%@\n\n@end",implementationStr];
    }
    self.jsonTF.stringValue = [NSString stringWithFormat:@"%@\n\n%@",self.jsonTF.stringValue,implementationStr];
}


///遍历字典获取属性
- (NSString *)configDictionary:(NSDictionary *)dict name:(NSString *)name{
    MyType *type = [[MyType alloc]init];
    type.Nmae = name;
    type.List = [NSMutableArray array];
    [self.implementationArray addObject:type];
    NSString *str = @"";
    for (NSString *key in dict) {
        str = [NSString stringWithFormat:@"%@%@",str,[self judgeTypeForKey:key value:dict[key]]];
    }
    return  str;
}


///判断字典的value的类型
- (NSString *) judgeTypeForKey:(NSString *)key value:(NSObject *)value {
    MyType *type = self.implementationArray.lastObject;
    NSString *UpKey = [key capitalizedString];
    NSString *prefix = self.prefixTf.stringValue.length ? self.prefixTf.stringValue : @"";
    if([value isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)value;
        NSString *str = [NSString stringWithFormat:@"@interface %@%@Model : NSObject\n",prefix,UpKey];
        str = [NSString stringWithFormat:@"%@%@@end",str,[self configDictionary:(NSDictionary *)array.firstObject name:[NSString stringWithFormat:@"%@%@Model",prefix,UpKey]]];
        self.jsonTF.stringValue = [NSString stringWithFormat:@"%@\n\n%@",self.jsonTF.stringValue,str];
        NSDictionary *sDict = @{@"id":@"2",@"name":@"key",@"class":[NSString stringWithFormat:@"%@%@Model",prefix,UpKey]};
        [type.List addObject:sDict];
        [self.implementationArray replaceObjectAtIndex:[self.implementationArray indexOfObject:type] withObject:type];
        return [NSString stringWithFormat:@"@property (nonatomic,strong) NSArray <%@%@Model *>*%@List;\n",prefix,UpKey,key];
    } else if([value isKindOfClass:[NSDictionary class]]) {
        NSString *str = [NSString stringWithFormat:@"@interface %@%@Model : NSObject\n",prefix,UpKey];
        str = [NSString stringWithFormat:@"%@%@@end",str,[self configDictionary:(NSDictionary *)value name:[NSString stringWithFormat:@"%@%@Model",prefix,UpKey]]];
        self.jsonTF.stringValue = [NSString stringWithFormat:@"%@\n\n%@",self.jsonTF.stringValue,str];
        NSDictionary *sDict = @{@"id":@"1",@"name":@"key",@"class":[NSString stringWithFormat:@"%@%@Model",prefix,UpKey]};
        [type.List addObject:sDict];
        [self.implementationArray replaceObjectAtIndex:[self.implementationArray indexOfObject:type] withObject:type];
        return [NSString stringWithFormat:@"@property (nonatomic,strong) %@%@Model *%@;\n",prefix,UpKey,key];
    } else if([value isKindOfClass:[NSNumber class]]){
        NSNumber *valueType = (NSNumber *)value;
        const char *objCType = valueType.objCType;
        NSString *str = @"NSInteger";
        if (*objCType == 'f' || *objCType == 'd') {
            str = @"double  ";
        } else if (*objCType == 'c' || *objCType == 'B') {
            str = @"BOOL    ";
        }
        return [NSString stringWithFormat:@"@property (nonatomic,assign) %@ %@;\n",str,key];
    } else  {
        return [NSString stringWithFormat:@"@property (nonatomic,copy  ) NSString *%@;\n",key];
    }
}



- (void)alertMsg:(NSString *)msg {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];
    [alert setMessageText:msg];
    [alert setInformativeText:@"请输入正确格式的json"];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn){
            [self.jsonTF setStringValue:@""];
        }else if(returnCode == NSAlertSecondButtonReturn){
        }
    }];
}

@end
