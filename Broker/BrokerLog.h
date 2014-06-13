//
//  BrokerLog.h
//  Broker
//
//  Created by Andrew Smith on 6/13/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#ifndef Broker_BrokerLog_h
#define Broker_BrokerLog_h

#define BROKER_LOG 1

#if defined(DEBUG) && defined(BROKER_LOG)
    #define BrokerLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
    #define BrokerWarningLog(...) NSLog(@"\n!!!!\n%s %@\n!!!!\n", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
    #define BrokerLog(...) do { } while (0)
    #define BrokerWarningLog(...) do { } while (0)
#endif

#ifndef NS_BLOCK_ASSERTIONS
    #define NS_BLOCK_ASSERTIONS
#endif

#endif
