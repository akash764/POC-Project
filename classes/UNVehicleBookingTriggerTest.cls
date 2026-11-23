/**
 * @description Unit tests for UNVehicleBookingTrigger, UNVehicleBookingTriggerHandler,
 * and UNSiteVisitCompletionSchedulable.
 */
@isTest
private class UNVehicleBookingTriggerTest {

    @testSetup
    static void setupData() {
        Lead testLead = new Lead(
            FirstName = 'Unit',
            LastName = 'TestLead',
            Company = 'UrbanNest Test',
            Phone = '9876543210',
            Email = 'unittest@urbannest.com',
            Status = 'New'
        );
        insert testLead;

        Project__c testProject = new Project__c(
            Name = 'Azure Heights',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Status__c = 'Active'
        );
        insert testProject;
    }

    @isTest
    static void testPreventMultipleActiveBookings() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        // First active booking
        Vehicle_Booking__c vb1 = new Vehicle_Booking__c(
            Lead__c = ld.Id,
            Destination_Project__c = proj.Id,
            Status__c = 'Requested',
            Vehicle_Type__c = 'Luxury Sedan',
            Number_of_Passengers__c = 2
        );
        insert vb1;

        // Attempt second active booking for the same Lead
        Vehicle_Booking__c vb2 = new Vehicle_Booking__c(
            Lead__c = ld.Id,
            Destination_Project__c = proj.Id,
            Status__c = 'Requested',
            Vehicle_Type__c = 'Premium SUV',
            Number_of_Passengers__c = 1
        );

        Test.startTest();
        try {
            insert vb2;
            Assert.fail('Expected exception for multiple active bookings');
        } catch (DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('An active Vehicle Booking'), 'Expected active booking error: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventExceedingThreeProjectBookings() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        // Create 3 completed bookings for this project
        List<Vehicle_Booking__c> listBookings = new List<Vehicle_Booking__c>();
        for (Integer i = 1; i <= 3; i++) {
            listBookings.add(new Vehicle_Booking__c(
                Lead__c = ld.Id,
                Destination_Project__c = proj.Id,
                Status__c = 'Completed',
                Vehicle_Type__c = 'Luxury Sedan',
                Number_of_Passengers__c = 2
            ));
        }
        insert listBookings;

        // Attempt 4th booking for the same project
        Vehicle_Booking__c vb4 = new Vehicle_Booking__c(
            Lead__c = ld.Id,
            Destination_Project__c = proj.Id,
            Status__c = 'Requested',
            Vehicle_Type__c = 'Premium SUV',
            Number_of_Passengers__c = 1
        );

        Test.startTest();
        try {
            insert vb4;
            Assert.fail('Expected exception for exceeding 3 project bookings');
        } catch (DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('Maximum limit reached'), 'Expected max project limit error: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testPastEventCompletion() {
        Lead ld = [SELECT Id, Status FROM Lead LIMIT 1];

        // Create an Event in the past
        Event pastEvent = new Event(
            Subject = 'Site Visit Past',
            WhoId = ld.Id,
            StartDateTime = DateTime.now().addDays(-2),
            EndDateTime = DateTime.now().addDays(-2).addHours(2),
            Transport_Required__c = false
        );
        insert pastEvent;

        Test.startTest();
        // Verify trigger/schedulable marks it completed
        UNSiteVisitCompletionSchedulable.runSync();
        Test.stopTest();

        Event evResult = [SELECT Id, Site_Visit_Status__c FROM Event WHERE Id = :pastEvent.Id];
        Assert.areEqual('Completed', evResult.Site_Visit_Status__c, 'Past event should be marked Completed');

        Lead ldResult = [SELECT Id, Status FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual('Site Visit Completed', ldResult.Status, 'Lead should be marked Site Visit Completed');
    }
}