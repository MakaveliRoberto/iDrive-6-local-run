// Data of a car used for the EFIPluginSimulator

// [!] required in EFIPluginSimulator.js

var car = {
            // < Test config>
            "testCase" : 0, //(0 = normal case, 1 = unknown Error, 2 = error1 (if defined), 3 = error2 (if defined))
            "undefinedError" : "999_undefined", //displayed Message when ACK == false && DETAIL == ""
            // </ Test config>

        //4.1
            "tsType" : 4711, // number
        //4.2 New York
            "destLong" : -882868227, // number
            "destLat" : 486071649, // number
            "destDescr" : "#destDescr", // text
        //4.3
            "arrTime" : new time(12,11,10), // time
        //4.4
            "source" : "FM", // text = (FM, CD, DVB,…)
        //4.5
            "settings" : "#settings", // text
        //4.6
            "status" : "0", // number = (0 = stays; 1 = moving)
        //4.7
            "codriver" : "1", // number = (2 = none; 1 = at least one)
        //4.8
            "range" : 1000, // number
            "unit" : 1, // number = (1 = Kilometers; 2 = Miles) -DEPRECATED-
        //4.9
            //(4.1)"destLong" : "", // number
            //(4.1)"destLat" : "", // number
            //(4.1)"destDescr" : "", // text
        //4.10
            "destDistance" : 999, // number
            //(4.8)"unit" : "1", // number = (1 = Kilometers; 2 = Miles) -DEPRECATED-
        //4.11 Woodcliff Lake, NJ
            "driveDirection" : "E", // text = (N, NE, E,…)
            "posLat" : 489560260, // number -DEPRECATED-
            "posLong" : -883736061, // number -DEPRECATED-
            "driveAngle" : 90, // number
        //4.12
            "fueltype" : 2, // number = (1 = Petrol, 2 = Diesel)
        //4.13
            "departure" : new time(9,8,7), // time
            "duration" : new time(6,5,4), // time
            "journeyDistance" : 500.5, // number
            "avgSpeed" : 80, // number
            "avgConsumption" : 10.5, // number
        //4.14
            "totalDistance" : 99000.81, // number
            //(4.8)"unit" : "", // number = (1 = Kilometers; 2 = Miles) -DEPRECATED-
        //4.15
            "phone" : "#phone", // text
            "BTname" : "#BTname", // text
        //4.16
            "country" : "#country", // text
            "town" : "#town", // text
            "street" : "#street", // text
            "number" : "#number", // text
            "crossing" : "#crossing", // text
        //4.17
            //(4.11)"posLat" : "#posLat", // number
            //(4.11)"posLong" : "#posLong", // number
        //4.18
            "band" : "#band", // text
            "frequency" : 98.2, // number
            "stationName" : "#stationName", // text
            "radioTextPlus" : new radioTextPlus("#radioTextPlus"), // object
        //4.19
            "TVstation" : "#TVstation", // text
        //4.20
            "useragent" : "#useragent", // text
        //4.21
            "version" : "#version", // text

        //4.22 NEVER RETURNS

        //4.23
            "phoneNumber" : "#phonenumber", // text
            "answer" : 100010001, // number
            //(4.13)"duration" : "", // (!= duration 4.13 name conflict) time

        //4.24 TBD

        //4.25 TBD

        //4.26 NEVER RETURNS

        //4.27 TBD

        //4.28
            "homeURL" : "#homeURL", // text
        //4.29
            "VINRN" : "#VINRN", // text
        //4.30
            "URL" : "#URL" // text

        //4.31 TBD

        //4.32 TBD

        //4.33 TBD
};