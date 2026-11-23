/**
 * @description Unit test for UNSiteVisitFeedbackTrigger and handler.
 */
@IsTest
private class UNSiteVisitFeedbackTriggerTest {

    @IsTest
    static void testFeedbackCreationAndLeadStatusProgression() {
        Project__c p = new Project__c(
            Name = 'Skyline Heights Towers',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Status__c = 'Active'
        );
        insert p;

        Lead ld = new Lead(
            FirstName = 'Priya',
            LastName = 'Nair',
            Company = 'Priya Nair (Individual Buyer)',
            Phone = '9840098765',
            Email = 'priya.nair@example.com',
            LeadSource = 'Web Portal',
            Status = 'Site Visit Scheduled'
        );
        insert ld;

        Test.startTest();
        Site_Visit_Feedback__c fb = new Site_Visit_Feedback__c(
            Lead__c = ld.Id,
            Project_Visited__c = p.Id,
            Visit_Date__c = Date.today(),
            Overall_Rating__c = 'Hot (Ready to Book)',
            Budget_Suitability__c = 'Within Budget',
            Preferred_BHK_or_Unit__c = '3 BHK',
            Pricing_Perception__c = 'Attractive / High Value',
            Accompanying_Visitors__c = 'With Spouse',
            Detailed_Remarks__c = 'Client loved the 12th-floor sea-view unit. Requested formal cost sheet.'
        );
        insert fb;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, Status, Preferred_Project__c, BHK_Preference__c 
            FROM Lead 
            WHERE Id = :ld.Id
        ];

        System.assertEquals('Site Visit Completed', updatedLead.Status, 'Lead status must update to Site Visit Completed');
        System.assertEquals(p.Id, updatedLead.Preferred_Project__c, 'Preferred project should be populated from feedback');
        System.assertEquals('3 BHK', updatedLead.BHK_Preference__c, 'BHK preference should sync from feedback');
    }
}