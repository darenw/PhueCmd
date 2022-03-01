// Bulb.d
//
// A Bulb object is our representative, or ambassador, to one specific physical bulb.
// During runtime, there are normally as many Bulb objects in a PhueSystem as there
// are physical bulbs to be controlled. 
// 
// Bulb know how to relate user-space concepts such as color, brightness changes
// to JSON for use by the HTTP REST interface. It does not actually perform any http though;
// this is up to the Hub object which in most use cases there is only one of.
// Hub knows the IP address and other mumbo-jumbo to perform the http REST work.



/*TODO*/ // steal the Bulb code out of the original monster file phuecmd.d
 
 
