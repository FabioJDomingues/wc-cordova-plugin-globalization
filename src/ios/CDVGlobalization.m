/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVGlobalization.h"

@implementation CDVGlobalization

- (void)pluginInitialize
{
    currentLocale = CFLocaleCopyCurrent();
}

- (void)getPreferredLanguage:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    // Source: http://stackoverflow.com/questions/3910244/getting-current-device-language-in-ios
    // (should be OK)
    NSString* language = [[NSLocale preferredLanguages] objectAtIndex:0];

    if (language) {
        //Format to match other devices
        if(language.length <= 2) {
            NSLocale* locale = [NSLocale currentLocale];
            NSString* localeId = [locale localeIdentifier];
            NSRange underscoreIndex = [localeId rangeOfString:@"_" options:NSBackwardsSearch];
            NSRange atSignIndex = [localeId rangeOfString:@"@"];
            if (underscoreIndex.location != NSNotFound) {
                //If localeIdentifier did not contain @, i.e. did not have calendar other than Gregoarian selected
                if(atSignIndex.length == 0)
                    language = [NSString stringWithFormat:@"%@%@", language, [localeId substringFromIndex:underscoreIndex.location]];
                else {
                    NSRange localeRange = NSMakeRange(underscoreIndex.location, atSignIndex.location-underscoreIndex.location);
                    language = [NSString stringWithFormat:@"%@%@", language, [localeId substringWithRange:localeRange]];
                }
            }
        }
        
        language = [language stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:language forKey:@"value"];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:dictionary];
    } else {
        // TBD is this ever expected to happen?
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_UNKNOWN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unknown error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

@implementation DeviceRegion
- (void)getCountryCode:(CDVInvokedUrlCommand*)command {
    NSLocale *locale = [NSLocale currentLocale];
    NSString *regionCode = [locale objectForKey:NSLocaleCountryCode];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:regionCode];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@implementation DeviceRegion
- (void)getCountryCode_Alternative:(CDVInvokedUrlCommand*)command {
    NSLocale *locale = [NSLocale currentLocale];
    NSString *regionCode = [locale objectForKey:NSLocaleCountryCode];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:regionCode];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getLocaleName:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSDictionary* dictionary = nil;

    NSLocale* locale = [NSLocale currentLocale];

    if (locale) {
        NSString *localeIdentifier = [[locale localeIdentifier] stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

        dictionary = [NSDictionary dictionaryWithObject:localeIdentifier forKey:@"value"];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    } else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_UNKNOWN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unknown error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

- (void)dateToString:(CDVInvokedUrlCommand*)command
{
    CFDateFormatterStyle style = kCFDateFormatterShortStyle;
    CFDateFormatterStyle dateStyle = kCFDateFormatterShortStyle;
    CFDateFormatterStyle timeStyle = kCFDateFormatterShortStyle;
    NSDate* date = nil;
    NSString* dateString = nil;
    CDVPluginResult* result = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    id milliseconds = [options valueForKey:@"date"];

    if (milliseconds && [milliseconds isKindOfClass:[NSNumber class]]) {
        // get the number of seconds since 1970 and create the date object
        date = [NSDate dateWithTimeIntervalSince1970:[milliseconds doubleValue] / 1000];
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];
    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired format length
                if ([key isEqualToString:@"formatLength"]) {
                    if ([item isEqualToString:@"short"]) {
                        style = kCFDateFormatterShortStyle;
                    } else if ([item isEqualToString:@"medium"]) {
                        style = kCFDateFormatterMediumStyle;
                    } else if ([item isEqualToString:@"long"]) {
                        style = kCFDateFormatterLongStyle;
                    } else if ([item isEqualToString:@"full"]) {
                        style = kCFDateFormatterFullStyle;
                    }
                }
                // get the type of date and time to generate
                else if ([key isEqualToString:@"selector"]) {
                    if ([item isEqualToString:@"date"]) {
                        dateStyle = style;
                        timeStyle = kCFDateFormatterNoStyle;
                    } else if ([item isEqualToString:@"time"]) {
                        dateStyle = kCFDateFormatterNoStyle;
                        timeStyle = style;
                    } else if ([item isEqualToString:@"date and time"]) {
                        dateStyle = style;
                        timeStyle = style;
                    }
                }
            }
        }
    }

    // create the formatter using the user's current default locale and formats for dates and times
    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            dateStyle,
            timeStyle);
    // if we have a valid date object then call the formatter
    if (date) {
        dateString = (__bridge_transfer NSString*)CFDateFormatterCreateStringWithDate(kCFAllocatorDefault,
                formatter,
                (__bridge CFDateRef)date);
    }

    // if the date was converted to a string successfully then return the result
    if (dateString) {
        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:dateString forKey:@"value"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        // DLog(@"GlobalizationCommand dateToString unable to format %@", [date description]);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_FORMATTING_ERROR] forKey:@"code"];
        [dictionary setValue:@"Formatting error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)stringToDate:(CDVInvokedUrlCommand*)command
{
    CFDateFormatterStyle style = kCFDateFormatterShortStyle;
    CFDateFormatterStyle dateStyle = kCFDateFormatterShortStyle;
    CFDateFormatterStyle timeStyle = kCFDateFormatterShortStyle;
    CDVPluginResult* result = nil;
    NSString* dateString = nil;
    NSDateComponents* comps = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    // get the string that is to be parsed for a date
    id ms = [options valueForKey:@"dateString"];

    if (ms && [ms isKindOfClass:[NSString class]]) {
        dateString = ms;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];
    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired format length
                if ([key isEqualToString:@"formatLength"]) {
                    if ([item isEqualToString:@"short"]) {
                        style = kCFDateFormatterShortStyle;
                    } else if ([item isEqualToString:@"medium"]) {
                        style = kCFDateFormatterMediumStyle;
                    } else if ([item isEqualToString:@"long"]) {
                        style = kCFDateFormatterLongStyle;
                    } else if ([item isEqualToString:@"full"]) {
                        style = kCFDateFormatterFullStyle;
                    }
                }
                // get the type of date and time to generate
                else if ([key isEqualToString:@"selector"]) {
                    if ([item isEqualToString:@"date"]) {
                        dateStyle = style;
                        timeStyle = kCFDateFormatterNoStyle;
                    } else if ([item isEqualToString:@"time"]) {
                        dateStyle = kCFDateFormatterNoStyle;
                        timeStyle = style;
                    } else if ([item isEqualToString:@"date and time"]) {
                        dateStyle = style;
                        timeStyle = style;
                    }
                }
            }
        }
    }

    // get the user's default settings for date and time formats
    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            dateStyle,
            timeStyle);

    // set the parsing to be more lenient
    CFDateFormatterSetProperty(formatter, kCFDateFormatterIsLenient, kCFBooleanTrue);

    // parse tha date and time string
    CFDateRef date = CFDateFormatterCreateDateFromString(kCFAllocatorDefault,
            formatter,
            (__bridge CFStringRef)dateString,
            NULL);

    // if we were able to parse the date then get the date and time components
    if (date != NULL) {
        NSCalendar* calendar = [NSCalendar currentCalendar];

        unsigned unitFlags = NSCalendarUnitYear |
            NSCalendarUnitMonth |
            NSCalendarUnitDay |
            NSCalendarUnitHour |
            NSCalendarUnitMinute |
            NSCalendarUnitSecond;

        comps = [calendar components:unitFlags fromDate:(__bridge NSDate*)date];
        CFRelease(date);
    }

    // put the various elements of the date and time into a dictionary
    if (comps != nil) {
        NSArray* keys = [NSArray arrayWithObjects:@"year", @"month", @"day", @"hour", @"minute", @"second", @"millisecond", nil];
        NSArray* values = [NSArray arrayWithObjects:[NSNumber numberWithInteger:[comps year]],
            [NSNumber numberWithInteger:[comps month] - 1],
            [NSNumber numberWithInteger:[comps day]],
            [NSNumber numberWithInteger:[comps hour]],
            [NSNumber numberWithInteger:[comps minute]],
            [NSNumber numberWithInteger:[comps second]],
            [NSNumber numberWithInteger:0],                /* iOS does not provide milliseconds */
            nil];

        NSDictionary* dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        // Dlog(@"GlobalizationCommand stringToDate unable to parse %@", dateString);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_PARSING_ERROR] forKey:@"code"];
        [dictionary setValue:@"unable to parse" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)getDatePattern:(CDVInvokedUrlCommand*)command
{
    CFDateFormatterStyle style = kCFDateFormatterShortStyle;
    CFDateFormatterStyle dateStyle = kCFDateFormatterShortStyle;
    CFDateFormatterStyle timeStyle = kCFDateFormatterShortStyle;
    CDVPluginResult* result = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];

    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired format length
                if ([key isEqualToString:@"formatLength"]) {
                    if ([item isEqualToString:@"short"]) {
                        style = kCFDateFormatterShortStyle;
                    } else if ([item isEqualToString:@"medium"]) {
                        style = kCFDateFormatterMediumStyle;
                    } else if ([item isEqualToString:@"long"]) {
                        style = kCFDateFormatterLongStyle;
                    } else if ([item isEqualToString:@"full"]) {
                        style = kCFDateFormatterFullStyle;
                    }
                }
                // get the type of date and time to generate
                else if ([key isEqualToString:@"selector"]) {
                    if ([item isEqualToString:@"date"]) {
                        dateStyle = style;
                        timeStyle = kCFDateFormatterNoStyle;
                    } else if ([item isEqualToString:@"time"]) {
                        dateStyle = kCFDateFormatterNoStyle;
                        timeStyle = style;
                    } else if ([item isEqualToString:@"date and time"]) {
                        dateStyle = style;
                        timeStyle = style;
                    }
                }
            }
        }
    }

    // get the user's default settings for date and time formats
    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            dateStyle,
            timeStyle);

    // get the date pattern to apply when formatting and parsing
    CFStringRef datePattern = CFDateFormatterGetFormat(formatter);
    // get the user's current time zone information
    CFTimeZoneRef timezone = (CFTimeZoneRef)CFDateFormatterCopyProperty(formatter, kCFDateFormatterTimeZone);

    // put the pattern and time zone information into the dictionary
    if ((datePattern != nil) && (timezone != nil)) {
        NSArray* keys = [NSArray arrayWithObjects:@"pattern", @"timezone", @"iana_timezone", @"utc_offset", @"dst_offset", nil];
        NSArray* values = [NSArray arrayWithObjects:((__bridge NSString*)datePattern),
            [((__bridge NSTimeZone*)timezone)abbreviation],
            [((__bridge NSTimeZone*)timezone)name],
            [NSNumber numberWithLong:[((__bridge NSTimeZone*)timezone)secondsFromGMT]],
            [NSNumber numberWithDouble:[((__bridge NSTimeZone*)timezone)daylightSavingTimeOffset]],
            nil];

        NSDictionary* dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_PATTERN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Pattern error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    if (timezone) {
        CFRelease(timezone);
    }
    CFRelease(formatter);
}

- (void)getDateNames:(CDVInvokedUrlCommand*)command
{
    int style = CDV_FORMAT_LONG;
    int selector = CDV_SELECTOR_MONTHS;
    CFStringRef dataStyle = kCFDateFormatterMonthSymbols;
    CDVPluginResult* result = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];

    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired type of name
                if ([key isEqualToString:@"type"]) {
                    if ([item isEqualToString:@"narrow"]) {
                        style = CDV_FORMAT_SHORT;
                    } else if ([item isEqualToString:@"wide"]) {
                        style = CDV_FORMAT_LONG;
                    }
                }
                // determine if months or days are needed
                else if ([key isEqualToString:@"item"]) {
                    if ([item isEqualToString:@"months"]) {
                        selector = CDV_SELECTOR_MONTHS;
                    } else if ([item isEqualToString:@"days"]) {
                        selector = CDV_SELECTOR_DAYS;
                    }
                }
            }
        }
    }

    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            kCFDateFormatterFullStyle,
            kCFDateFormatterFullStyle);

    if ((selector == CDV_SELECTOR_MONTHS) && (style == CDV_FORMAT_LONG)) {
        dataStyle = kCFDateFormatterMonthSymbols;
    } else if ((selector == CDV_SELECTOR_MONTHS) && (style == CDV_FORMAT_SHORT)) {
        dataStyle = kCFDateFormatterShortMonthSymbols;
    } else if ((selector == CDV_SELECTOR_DAYS) && (style == CDV_FORMAT_LONG)) {
        dataStyle = kCFDateFormatterWeekdaySymbols;
    } else if ((selector == CDV_SELECTOR_DAYS) && (style == CDV_FORMAT_SHORT)) {
        dataStyle = kCFDateFormatterShortWeekdaySymbols;
    }

    CFArrayRef names = (CFArrayRef)CFDateFormatterCopyProperty(formatter, dataStyle);

    if (names) {
        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:((__bridge NSArray*)names) forKey:@"value"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        CFRelease(names);
    }
    // error
    else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_UNKNOWN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unknown error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)isDayLightSavingsTime:(CDVInvokedUrlCommand*)command
{
    NSDate* date = nil;
    CDVPluginResult* result = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    id milliseconds = [options valueForKey:@"date"];

    if (milliseconds && [milliseconds isKindOfClass:[NSNumber class]]) {
        // get the number of seconds since 1970 and create the date object
        date = [NSDate dateWithTimeIntervalSince1970:[milliseconds doubleValue] / 1000];
    }

    if (date) {
        // get the current calendar for the user and check if the date is using DST
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSTimeZone* timezone = [calendar timeZone];
        NSNumber* dst = [NSNumber numberWithBool:[timezone isDaylightSavingTimeForDate:date]];

        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:dst forKey:@"dst"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_UNKNOWN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unknown error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }
    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

- (void)getFirstDayOfWeek:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    NSCalendar* calendar = [NSCalendar autoupdatingCurrentCalendar];

    NSNumber* day = [NSNumber numberWithInteger:[calendar firstWeekday]];

    if (day) {
        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:day forKey:@"value"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_UNKNOWN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unknown error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

- (void)numberToString:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    CFNumberFormatterStyle style = kCFNumberFormatterDecimalStyle;
    NSNumber* number = nil;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    id value = [options valueForKey:@"number"];

    if (value && [value isKindOfClass:[NSNumber class]]) {
        number = (NSNumber*)value;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];
    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired style of formatting
                if ([key isEqualToString:@"type"]) {
                    if ([item isEqualToString:@"percent"]) {
                        style = kCFNumberFormatterPercentStyle;
                    } else if ([item isEqualToString:@"currency"]) {
                        style = kCFNumberFormatterCurrencyStyle;
                    } else if ([item isEqualToString:@"decimal"]) {
                        style = kCFNumberFormatterDecimalStyle;
                    }
                }
            }
        }
    }

    CFNumberFormatterRef formatter = CFNumberFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            style);

    // get the localized string based upon the locale and user preferences
    NSString* numberString = (__bridge_transfer NSString*)CFNumberFormatterCreateStringWithNumber(kCFAllocatorDefault,
            formatter,
            (__bridge CFNumberRef)number);

    if (numberString) {
        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:numberString forKey:@"value"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        // DLog(@"GlobalizationCommand numberToString unable to format %@", [number stringValue]);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_FORMATTING_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unable to format" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)stringToNumber:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    CFNumberFormatterStyle style = kCFNumberFormatterDecimalStyle;
    NSString* numberString = nil;
    double doubleValue;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    id value = [options valueForKey:@"numberString"];

    if (value && [value isKindOfClass:[NSString class]]) {
        numberString = (NSString*)value;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];
    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired style of formatting
                if ([key isEqualToString:@"type"]) {
                    if ([item isEqualToString:@"percent"]) {
                        style = kCFNumberFormatterPercentStyle;
                    } else if ([item isEqualToString:@"currency"]) {
                        style = kCFNumberFormatterCurrencyStyle;
                    } else if ([item isEqualToString:@"decimal"]) {
                        style = kCFNumberFormatterDecimalStyle;
                    }
                }
            }
        }
    }

    CFNumberFormatterRef formatter = CFNumberFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            style);

    // we need to make this lenient so as to avoid problems with parsing currencies that have non-breaking space characters
    if (style == kCFNumberFormatterCurrencyStyle) {
        CFNumberFormatterSetProperty(formatter, kCFNumberFormatterIsLenient, kCFBooleanTrue);
    }

    // parse againist the largest type to avoid data loss
    Boolean rc = CFNumberFormatterGetValueFromString(formatter,
            (__bridge CFStringRef)numberString,
            NULL,
            kCFNumberDoubleType,
            &doubleValue);

    if (rc) {
        NSDictionary* dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:doubleValue] forKey:@"value"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        // DLog(@"GlobalizationCommand stringToNumber unable to parse %@", numberString);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_PARSING_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unable to parse" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)getNumberPattern:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    CFNumberFormatterStyle style = kCFNumberFormatterDecimalStyle;
    CFStringRef symbolType = NULL;
    NSString* symbol = @"";

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    // see if any options have been specified
    id items = [options valueForKey:@"options"];

    if (items && [items isKindOfClass:[NSMutableDictionary class]]) {
        NSEnumerator* enumerator = [items keyEnumerator];
        id key;

        // iterate through all the options
        while ((key = [enumerator nextObject])) {
            id item = [items valueForKey:key];

            // make sure that only string values are present
            if ([item isKindOfClass:[NSString class]]) {
                // get the desired style of formatting
                if ([key isEqualToString:@"type"]) {
                    if ([item isEqualToString:@"percent"]) {
                        style = kCFNumberFormatterPercentStyle;
                    } else if ([item isEqualToString:@"currency"]) {
                        style = kCFNumberFormatterCurrencyStyle;
                    } else if ([item isEqualToString:@"decimal"]) {
                        style = kCFNumberFormatterDecimalStyle;
                    }
                }
            }
        }
    }

    CFNumberFormatterRef formatter = CFNumberFormatterCreate(kCFAllocatorDefault,
            currentLocale,
            style);

    NSString* numberPattern = (__bridge NSString*)CFNumberFormatterGetFormat(formatter);

    if (style == kCFNumberFormatterCurrencyStyle) {
        symbolType = kCFNumberFormatterCurrencySymbol;
    } else if (style == kCFNumberFormatterPercentStyle) {
        symbolType = kCFNumberFormatterPercentSymbol;
    }

    if (symbolType) {
        symbol = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, symbolType);
    }

    NSString* decimal = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterDecimalSeparator);
    NSString* grouping = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterGroupingSeparator);
    NSString* posSign = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterPlusSign);
    NSString* negSign = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterMinusSign);
    NSNumber* fracDigits = (__bridge_transfer NSNumber*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterMinFractionDigits);
    NSNumber* roundingDigits = (__bridge_transfer NSNumber*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterRoundingIncrement);

    // put the pattern information into the dictionary
    if (numberPattern != nil) {
        NSArray* keys = [NSArray arrayWithObjects:@"pattern", @"symbol", @"fraction", @"rounding",
            @"positive", @"negative", @"decimal", @"grouping", nil];
        NSArray* values = [NSArray arrayWithObjects:numberPattern, symbol, fracDigits, roundingDigits,
            posSign, negSign, decimal, grouping, nil];
        NSDictionary* dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    }
    // error
    else {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_PATTERN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Pattern error" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

    CFRelease(formatter);
}

- (void)getCurrencyPattern:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* currencyCode = nil;
    NSString* numberPattern = nil;
    NSString* decimal = nil;
    NSString* grouping = nil;
    int32_t defaultFractionDigits;
    double roundingIncrement;
    Boolean rc;

    NSDictionary* options;

    if ([command.arguments count] > 0) {
        options = [command argumentAtIndex:0];
    }
    if (!options) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no options given"];
        [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        return;
    }

    id value = [options valueForKey:@"currencyCode"];

    if (value && [value isKindOfClass:[NSString class]]) {
        currencyCode = (NSString*)value;
    }

    // first see if there is base currency info available and fill in the currency_info structure
    rc = CFNumberFormatterGetDecimalInfoForCurrencyCode((__bridge CFStringRef)currencyCode, &defaultFractionDigits, &roundingIncrement);

    // now set the currency code in the formatter
    if (rc) {
        CFNumberFormatterRef formatter = CFNumberFormatterCreate(kCFAllocatorDefault,
                currentLocale,
                kCFNumberFormatterCurrencyStyle);

        CFNumberFormatterSetProperty(formatter, kCFNumberFormatterCurrencyCode, (__bridge CFStringRef)currencyCode);
        CFNumberFormatterSetProperty(formatter, kCFNumberFormatterInternationalCurrencySymbol, (__bridge CFStringRef)currencyCode);

        numberPattern = (__bridge NSString*)CFNumberFormatterGetFormat(formatter);
        decimal = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterCurrencyDecimalSeparator);
        grouping = (__bridge_transfer NSString*)CFNumberFormatterCopyProperty(formatter, kCFNumberFormatterCurrencyGroupingSeparator);

        NSArray* keys = [NSArray arrayWithObjects:@"pattern", @"code", @"fraction", @"rounding",
            @"decimal", @"grouping", nil];
        NSArray* values = [NSArray arrayWithObjects:numberPattern, currencyCode, [NSNumber numberWithInt:defaultFractionDigits],
            [NSNumber numberWithDouble:roundingIncrement], decimal, grouping, nil];
        NSDictionary* dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        CFRelease(formatter);
    }
    // error
    else {
        // DLog(@"GlobalizationCommand getCurrencyPattern unable to get pattern for %@", currencyCode);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        [dictionary setValue:[NSNumber numberWithInt:CDV_PATTERN_ERROR] forKey:@"code"];
        [dictionary setValue:@"Unable to get pattern" forKey:@"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

- (void)dealloc
{
    if (currentLocale) {
        CFRelease(currentLocale);
        currentLocale = nil;
    }
}

@end
