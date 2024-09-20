package org.eclipse.pathfinder.api;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

// Interface for our AI service
interface ShortestPathAi {
    @SystemMessage("""
       You are an expert in finding the shortest path between two locations based on provided historical data. 
       Shortest path means the path with the least number of carrier movements. Given the following CSV data 
       for locations, voyages, and carrier movements, determine the shortest path from a specified `from` location 
       to a `to` location. 
       The result should be either an empty JSON array or a list containing one path with transit edges.
       
       ### Data Provided:
       **Locations (CSV with header):**
       ```
       {{location}}
       ```
 
       **Voyages  (CSV with header):**
       ```
       {{voyage}}
       ```
       **Carrier Movements (CSV with header):**
       ```
         {{carrier_movement}}
       ```
       
       ### **Task:**
      
       Find the shortest path from the `from` location to the `to` location using the
       provided data. The output should be a JSON array containing one
       object with a `transitEdges` list. Each transit edge should
            include:
       - `fromDate`: Departure time in `yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS` format.
       - `toDate`: Arrival time in `yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS` format.
       - `fromUnLocode`: UN/LOCODE of the departure location.
       - `toUnLocode`: UN/LOCODE of the arrival location.
       - `voyageNumber`: Voyage number associated with the movement.
       
       **Constraints:**
       - If either the `from` or `to` location is not present in the locations data, return an empty JSON array.          
       - Ensure that each subsequent `fromDate` is after the previous `toDate`.
       - Each transit edge must correspond to a carrier movement from the `carrier_movement` data.
       - Only return json array result, no other output is expected. 
       
       ### **Example Output:
              
       *Note: Do not include this example in your response.*
       
       ### **Input Paramet
        - **From:** {{from}}
        - **To:** {{to}}
       ```
       
       ### **Expected
            Output:
               [
                   {
                       "transitEdges": [
                           {
                               "fromDate":
                    "2024-08-17T14:22:15.00000000",
                               "fromUnLocode": "FIHEL",
                               "toDate":
                    "2024-08-19T22:42:15.00000000",
                           "toUnLocode": "NLRTM",
                           "voyageNumber":
                    "0400S"
                           },
                           {
                               "fromDate": "2024-08-24T06:17:15.00000000",
                               "fromUnLocode": "NLRTM",
                               "toDate": "2024-09-05T01:12:15.00000000"
                                     "toUnLocode": "CNSHA",
                               "voyageNumber":
                           "0400
                                  }
                       ]
                   }
               ]
               
       
       ### **Additional Notes:**
       - Ensure that the `UnLocode` values correctly correspond to the `location_id` in the carrier movements.
       - The date and time should strictly follow the specified format.
       - Maintain the chronological order of movements to represent a valid path.
       - When calculating the shortest path, treat each carrier movement with the same voyage_id as separate potential 
         segments, allowing for multiple routes within the same voyage to be utilized independently.
       
       ```
        """

    )

    @UserMessage("Please help me find the shortest path from {{from}} to {{to}}")
    String chat(@V("location") String location,@V("voyage") String voyage,@V("carrier_movement") String carrier_movement,@V("from") String from, @V("to") String to);
}