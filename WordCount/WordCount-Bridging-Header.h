//
//  WordCount-Bridging-Header.h
//  WordCount
//
//  Created by iMAC i7 on 3/30/15.
//  Copyright (c) 2015 YuriiMobile. All rights reserved.
//

#import <OpenEars/OELanguageModelGenerator.h> // We need to import this here in order to use the delegate.
#import <OpenEars/OEPocketsphinxController.h> // Please note that unlike in previous versions of OpenEars, we now link the headers through the framework.
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>
#import <Slt/Slt.h>