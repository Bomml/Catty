/**
 *  Copyright (C) 2010-2013 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */


#import "Logger.h"

@interface Logger()

@property LogLevel logLevel;
@property (nonatomic, strong) NSDictionary* loggerProperties;

@end


@implementation Logger

static Logger* instance;

+(Logger*) instance {
    if(!instance) {
        instance = [[Logger alloc] init];
    }
    return instance;
}

-(Logger*) init
{
    self = [super init];
    if(self) {
        self.logLevel = kLogLevel;
        NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"LoggerProperties" ofType:@"plist"];
        self.loggerProperties = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    }
    return self;
}


+(void) debug:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    [[Logger instance] logAtLevel:debug withFormat:format arguments:args];
    va_end(args);
}

+(void) info:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    [[Logger instance] logAtLevel:info withFormat:format arguments:args];
    va_end(args);
}

+(void) warn:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    [[Logger instance] logAtLevel:warn withFormat:format arguments:args];
    va_end(args);
}

+(void) error:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    [[Logger instance] logAtLevel:error withFormat:format arguments:args];
    va_end(args);
}

+(void) logError:(NSError*)logError
{
    if(logError) {
        NSString* description = [logError localizedDescription];
        if(description) {
            [[Logger instance] logAtLevel:error withFormat:description arguments:nil];
        }
    }
}


-(void) logAtLevel:(LogLevel)level withFormat:(NSString*)format arguments:(va_list)args
{
    if(level >= self.logLevel) {
        NSString* callerClass = [self classNameForCaller];
        if([self loggingEnabledForClass:callerClass logLevel:level]) {
            NSString* log = [[NSString alloc] initWithFormat:format arguments:args];
            NSLog(@"[%@] %@: %@" ,[self stringForLogLevel:level], callerClass, log);
        }
        
        if(level == error && kAbortAtError) {
            abort();
        }
    }
}


-(BOOL)loggingEnabledForClass:(NSString*)className logLevel:(LogLevel)level
{    
    id classLvl = [self.loggerProperties objectForKey:className];
    LogLevel classLogLevel = debug;
    if(classLvl) {
        classLogLevel = [self logLevelForString:classLvl];
    }
    return level >= classLogLevel;
}


-(NSString*)classNameForCaller
{
    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:3];
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
    [array removeObject:@""];
    if([self isDispatchBlock:[array objectAtIndex:4]]) {
        return [array objectAtIndex:5];
    }
    return [array objectAtIndex:4];
    
}

-(NSString*)stringForLogLevel:(LogLevel)level{
    switch (level) {
        case debug:
            return @"DEBUG";
            break;
            
        case info:
            return @"INFO";
            break;
            
        case warn:
            return @"WARN";
            break;
            
        case error:
            return @"ERROR";
            break;
            
        default:
            return @"UNKNOWN";
            break;
    }
}

-(LogLevel)logLevelForString:(NSString*)level
{
    if([level isEqualToString:@"debug"]) {
        return debug;
    }
    if([level isEqualToString:@"info"]) {
        return info;
    }
    if([level isEqualToString:@"warn"]) {
        return warn;
    }
    if([level isEqualToString:@"error"]) {
        return error;
    }
    return -1;
}

-(BOOL) isDispatchBlock:(NSString*)block
{
    return [block hasPrefix:@"__"] ? YES : NO;
}





@end
