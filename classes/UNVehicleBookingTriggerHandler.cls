/**
 * @description Handler for Vehicle_Booking__c triggers.
 * Enforces business rules:
 * 1. Only ONE active Vehicle Booking per Lead (Status not in 'Completed', 'Cancelled').
 * 2. Maximum of 3 Vehicle Bookings per Lead for the same Project.
 */
public with sharing class UNVehicleBookingTriggerHandler {

    public static void validateBookings(List<Vehicle_Booking__c> newBookings, Map<Id, Vehicle_Booking__c> oldMap) {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();

        for (Vehicle_Booking__c vb : newBookings) {
            if (vb.Lead__c != null) {
                leadIds.add(vb.Lead__c);
            }
            if (vb.Destination_Project__c != null) {
                projectIds.add(vb.Destination_Project__c);
            }
        }

        if (leadIds.isEmpty()) {
            return;
        }

        // Query all existing bookings for these Leads
        List<Vehicle_Booking__c> existingBookings = [
            SELECT Id, Name, Lead__c, Destination_Project__c, Status__c
            FROM Vehicle_Booking__c
            WHERE Lead__c IN :leadIds
        ];

        // Map existing bookings by Lead for Active checks, and by Lead+Project for count checks
        Map<Id, List<Vehicle_Booking__c>> leadActiveBookingsMap = new Map<Id, List<Vehicle_Booking__c>>();
        Map<String, Integer> leadProjectCountMap = new Map<String, Integer>();

        for (Vehicle_Booking__c vb : existingBookings) {
            // Check active
            if (vb.Status__c != 'Completed' && vb.Status__c != 'Cancelled') {
                if (!leadActiveBookingsMap.containsKey(vb.Lead__c)) {
                    leadActiveBookingsMap.put(vb.Lead__c, new List<Vehicle_Booking__c>());
                }
                leadActiveBookingsMap.get(vb.Lead__c).add(vb);
            }

            // Check project count (non-cancelled)
            if (vb.Destination_Project__c != null && vb.Status__c != 'Cancelled') {
                String key = String.valueOf(vb.Lead__c) + '_' + String.valueOf(vb.Destination_Project__c);
                Integer count = leadProjectCountMap.containsKey(key) ? leadProjectCountMap.get(key) : 0;
                leadProjectCountMap.put(key, count + 1);
            }
        }

        for (Vehicle_Booking__c newVb : newBookings) {
            if (newVb.Lead__c == null) {
                continue;
            }

            Boolean isNewActive = (newVb.Status__c != 'Completed' && newVb.Status__c != 'Cancelled');

            // 1. Check Active Booking Rule
            if (isNewActive && leadActiveBookingsMap.containsKey(newVb.Lead__c)) {
                for (Vehicle_Booking__c existingActive : leadActiveBookingsMap.get(newVb.Lead__c)) {
                    // Exclude self if updating
                    if (newVb.Id == null || newVb.Id != existingActive.Id) {
                        newVb.addError('Cannot create Vehicle Booking: An active Vehicle Booking (' + existingActive.Name + ' - Status: ' + existingActive.Status__c + ') already exists for this Lead. You cannot create a new booking until the existing booking is Completed or Cancelled.');
                        break;
                    }
                }
            }

            // 2. Check Max 3 Per Project Rule (on insert or project change)
            if (newVb.Destination_Project__c != null && newVb.Status__c != 'Cancelled') {
                String key = String.valueOf(newVb.Lead__c) + '_' + String.valueOf(newVb.Destination_Project__c);
                Integer existingCount = leadProjectCountMap.containsKey(key) ? leadProjectCountMap.get(key) : 0;

                // If updating existing record with same project, don't count self twice
                if (newVb.Id != null && oldMap != null && oldMap.containsKey(newVb.Id)) {
                    if (oldMap.get(newVb.Id).Destination_Project__c == newVb.Destination_Project__c) {
                        existingCount--;
                    }
                }

                if (existingCount >= 3) {
                    newVb.addError('Cannot create Vehicle Booking: Maximum limit reached. A maximum of 3 vehicle bookings are permitted per project for a lead. This lead already has ' + existingCount + ' bookings registered for this project.');
                }
            }
        }
    }
}