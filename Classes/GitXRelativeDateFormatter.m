//
//  GitXRelativeDateFormatter.m
//  GitX
//
//  Created by Nathan Kinsinger on 9/1/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import "GitXRelativeDateFormatter.h"


#define MINUTE 60
#define HOUR   (60 * MINUTE)

#define WEEK 7


@implementation GitXRelativeDateFormatter

- (NSString *)stringForObjectValue:(id)date
{
	if (![date isKindOfClass:[NSDate class]])
		return nil;

    NSDate *now = [NSDate date];

    NSInteger secondsAgo = lround([now timeIntervalSinceDate:date]);

    if (secondsAgo < 0)
        return @"Future";

	if (secondsAgo < (2 * MINUTE))
		return @"1 mn";

	if (secondsAgo < HOUR)
		return [NSString stringWithFormat:@"%ld mns", (secondsAgo / MINUTE)];

	if (secondsAgo < (2 * HOUR))
		return @"1 hr";

	// figure out # of days ago based on calender days (so yesterday is the day before today not 24 hours ago)
	NSDateFormatter *midnightFormmatter = [[NSDateFormatter alloc] init];
	[midnightFormmatter setDateFormat:@"yyyy-MM-dd"];
	NSDate *midnightOnTargetDate = [midnightFormmatter dateFromString:[midnightFormmatter stringFromDate:date]];
	NSDate *midnightToday = [midnightFormmatter dateFromString:[midnightFormmatter stringFromDate:now]];

	// use NSCalendar so it will handle things like leap years correctly
	NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
																   fromDate:midnightOnTargetDate
																	 toDate:midnightToday
																	options:0];
	NSInteger yearsAgo = [components year];
	NSInteger monthsAgo = [components month];
	NSInteger daysAgo = [components day];

	if (yearsAgo < 2) {
		if (monthsAgo == 0) {
			// return "hours ago" if it's still today, but "Yesterday" only if more than 6 hours ago
			// gives people a little time to get used to the idea that yesterday is over :)
			if ((daysAgo == 0) || (secondsAgo < (6 * HOUR)))
				return [NSString stringWithFormat:@"%ld hrs", (secondsAgo / HOUR)];
			if (daysAgo == 1)
				return @"1 dy";

			if (daysAgo >= (2 * WEEK))
				return [NSString stringWithFormat:@"%ld wks", (daysAgo / WEEK)];

			return [NSString stringWithFormat:@"%ld dys", daysAgo];
		}

		if (monthsAgo == 1)
			return @"1 mth";

		return [NSString stringWithFormat:@"%ld mths", monthsAgo];
	}

	return [NSString stringWithFormat:@"%ld yrs", yearsAgo];
}

@end
