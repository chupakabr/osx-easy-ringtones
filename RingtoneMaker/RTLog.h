//
//  RTLog.h
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/29/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#ifndef RingtoneMaker_RTLog_h
#define RingtoneMaker_RTLog_h

#ifdef DEBUG
# define RTLog(args...) NSLog(args)
#else
# define RTLog(args...) 
#endif

#endif
