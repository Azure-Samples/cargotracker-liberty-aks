package org.eclipse.pathfinder.api;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

// Interface for our AI service
interface ShortestPathAi {
    @SystemMessage("""
        You will act as a expert who helps find the shortest 3 paths[transitEdges], the result 
        can be empty or less than 3 paths.
        Given the following historical location data, voyage data, and carrier_movement data (in CSV format with header).
        Don't use any external data. If there is no path, just give an empty result.
        This is an return value example of of shortest path from `CNHKG` to `USNYC` :
        ```
            [
                {
                    "transitEdges": [
                        {
                            "fromDate": "2024-09-14T18:24:44.70698604",
                            "fromUnLocode": "CNHKG",
                            "toDate": "2024-09-15T18:43:44.70698604",
                            "toUnLocode": "JNTKO",
                            "voyageNumber": "0301S"
                        },
                        {
                            "fromDate": "2024-09-18T02:08:44.70698604",
                            "fromUnLocode": "JNTKO",
                            "toDate": "2024-09-19T05:32:44.70698604",
                            "toUnLocode": "CNHGH",
                            "voyageNumber": "0100S"
                        },
                        {
                            "fromDate": "2024-09-21T05:53:44.70698604",
                            "fromUnLocode": "CNHGH",
                            "toDate": "2024-09-22T00:18:44.70698604",
                            "toUnLocode": "NLRTM",
                            "voyageNumber": "0200T"
                        },
                        {
                            "fromDate": "2024-09-24T04:23:44.70698604",
                            "fromUnLocode": "NLRTM",
                            "toDate": "2024-09-25T04:50:44.70698604",
                            "toUnLocode": "USNYC",
                            "voyageNumber": "0300A"
                        }
                    ]
                }
            ]
        ```
        The location data is as below:
        ---data-start---
                {{location}}        
        ---data-end---     
        The voyage data is as below:
        ---data-start---
                {{voyage}}
        ---data-end---
        The carrier_movement data is as below:
        ---data-start---  
                {{carrier_movement}}
        ---data-end---
        """
    )

    @UserMessage("Please help me find the shortest path from {{from}} to {{to}}")
    String chat(@V("location") String location,@V("voyage") String voyage,@V("carrier_movement") String carrier_movement,@V("from") String from, @V("to") String to);
}