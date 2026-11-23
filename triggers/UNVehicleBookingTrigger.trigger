/**
 * @description Trigger on Vehicle_Booking__c to enforce single active booking and project booking limits.
 */
trigger UNVehicleBookingTrigger on Vehicle_Booking__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            UNVehicleBookingTriggerHandler.validateBookings(Trigger.new, null);
        } else if (Trigger.isUpdate) {
            UNVehicleBookingTriggerHandler.validateBookings(Trigger.new, Trigger.oldMap);
        }
    }
}