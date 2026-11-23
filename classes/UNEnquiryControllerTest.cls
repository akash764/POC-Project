@IsTest
private class UNEnquiryControllerTest {

    @TestSetup
    static void setupData() {
        Project__c proj = new Project__c(
            Name = 'Urban Splendor',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu'
        );
        insert proj;

        Project__c proj2 = new Project__c(
            Name = 'Azure Heights',
            City__c = 'Bengaluru',
            State__c = 'Karnataka'
        );
        insert proj2;

        // Existing Lead to test deduplication on Urban Splendor
        Lead existing = new Lead(
            LastName = 'Sharma',
            FirstName = 'Rajesh',
            Company = 'Chennai',
            Email = 'rajesh.sharma@example.com',
            Phone = '+919876543210',
            Normalized_Email__c = 'rajesh.sharma@example.com',
            Normalized_Phone__c = '9876543210',
            Preferred_Project__c = proj.Id,
            LeadSource = 'Own Website',
            Status = 'New'
        );
        insert existing;
    }

    @IsTest
    static void testSubmitNewEnquirySuccess() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        UNEnquiryDTO dto = new UNEnquiryDTO();
        dto.submissionKey = 'SUB-UUID-001';
        dto.fullName = 'Priya Raman';
        dto.email = 'priya.raman@example.com';
        dto.phone = '+91 9988776655';
        dto.locationPreference = 'Anna Nagar, Chennai';
        dto.budget = 7500000;
        dto.bhkPreference = '2 BHK';
        dto.projectId = proj.Id;
        dto.whatsAppOptIn = true;

        Test.startTest();
        UNEnquiryResultDTO result = UNEnquiryController.submitEnquiry(dto);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Should return success');
        Assert.isTrue(result.message.contains('Thank you'), 'Should provide neutral thank you message');

        List<Lead> leads = [SELECT Id, LastName, Company, Location_Preference__c, Email, Normalized_Phone__c, Normalized_Email__c, WhatsApp_Opt_In__c, LeadSource FROM Lead WHERE Email = 'priya.raman@example.com'];
        Assert.areEqual(1, leads.size(), 'Should create one new lead');
        Assert.areEqual('Anna Nagar, Chennai', leads[0].Company);
        Assert.areEqual('Anna Nagar, Chennai', leads[0].Location_Preference__c);
        Assert.areEqual('Own Website', leads[0].LeadSource);
        Assert.areEqual('9988776655', leads[0].Normalized_Phone__c);
        Assert.isTrue(leads[0].WhatsApp_Opt_In__c);
    }

    @IsTest
    static void testDuplicatePhoneCreatesTaskNotLead() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Urban Splendor' LIMIT 1];

        UNEnquiryDTO dto = new UNEnquiryDTO();
        dto.submissionKey = 'SUB-UUID-002';
        dto.fullName = 'Rajesh S';
        dto.phone = '9876543210'; // Matches existing lead's phone for Urban Splendor
        dto.email = 'different.email@example.com';
        dto.budget = 9000000;
        dto.bhkPreference = '3 BHK';
        dto.projectId = proj.Id;
        dto.whatsAppOptIn = false;

        Integer countBefore = [SELECT COUNT() FROM Lead];

        Test.startTest();
        UNEnquiryResultDTO result = UNEnquiryController.submitEnquiry(dto);
        Test.stopTest();

        Assert.isFalse(result.isSuccess, 'Should reject repeated enquiry for same project');
        Assert.isTrue(result.message.contains('already been submitted'), 'Should explain enquiry is already submitted');
        Integer countAfter = [SELECT COUNT() FROM Lead];
        Assert.areEqual(countBefore, countAfter, 'Must NOT create a second Lead for the same project');

        List<Task> tasks = [SELECT Id, Subject, Priority FROM Task WHERE Subject LIKE '%Urban Splendor%'];
        Assert.areEqual(1, tasks.size(), 'Should create follow-up task for the owner');
    }

    @IsTest
    static void testSameCustomerDifferentProjectAllowed() {
        Project__c proj2 = [SELECT Id FROM Project__c WHERE Name = 'Azure Heights' LIMIT 1];

        UNEnquiryDTO dto = new UNEnquiryDTO();
        dto.submissionKey = 'SUB-UUID-003';
        dto.fullName = 'Rajesh Sharma';
        dto.phone = '9876543210'; // Same phone as existing lead
        dto.email = 'rajesh.sharma@example.com';
        dto.budget = 12000000;
        dto.bhkPreference = '4 BHK';
        dto.projectId = proj2.Id; // Different project!
        dto.locationPreference = 'Bengaluru';
        dto.whatsAppOptIn = true;

        Integer countBefore = [SELECT COUNT() FROM Lead];

        Test.startTest();
        UNEnquiryResultDTO result = UNEnquiryController.submitEnquiry(dto);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Should allow enquiry for different project');
        Integer countAfter = [SELECT COUNT() FROM Lead];
        Assert.areEqual(countBefore + 1, countAfter, 'Must create a new Lead for different project');
    }

    @IsTest
    static void testSubmissionKeyIdempotency() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        UNEnquiryDTO dto = new UNEnquiryDTO();
        dto.submissionKey = 'REPLAY-KEY-123';
        dto.fullName = 'Amit Kumar';
        dto.phone = '9123456780';
        dto.email = 'amit@example.com';
        dto.projectId = proj.Id;

        // First submission
        UNEnquiryController.submitEnquiry(dto);
        Integer countAfterFirst = [SELECT COUNT() FROM Lead WHERE Submission_Key__c = 'REPLAY-KEY-123'];
        Assert.areEqual(1, countAfterFirst);

        // Replay submission (identical key)
        Test.startTest();
        UNEnquiryResultDTO result = UNEnquiryController.submitEnquiry(dto);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Replayed submission should succeed neutrally');
        Integer countAfterSecond = [SELECT COUNT() FROM Lead WHERE Submission_Key__c = 'REPLAY-KEY-123'];
        Assert.areEqual(1, countAfterSecond, 'Should never insert duplicate on replayed key');
    }

    @IsTest
    static void testValidationErrors() {
        // Missing name
        UNEnquiryDTO noName = new UNEnquiryDTO();
        noName.phone = '9876543210';
        UNEnquiryResultDTO res1 = UNEnquiryController.submitEnquiry(noName);
        Assert.isFalse(res1.isSuccess);

        // Missing contact info
        UNEnquiryDTO noContact = new UNEnquiryDTO();
        noContact.fullName = 'Kavitha';
        UNEnquiryResultDTO res2 = UNEnquiryController.submitEnquiry(noContact);
        Assert.isFalse(res2.isSuccess);

        // Negative budget
        UNEnquiryDTO negBudget = new UNEnquiryDTO();
        negBudget.fullName = 'Kavitha';
        negBudget.phone = '9876543210';
        negBudget.budget = -500;
        UNEnquiryResultDTO res3 = UNEnquiryController.submitEnquiry(negBudget);
        Assert.isFalse(res3.isSuccess);
    }

    @IsTest
    static void testSubmitEnquiryWithCampaignAttribution() {
        Campaign camp = new Campaign(
            Name = 'Expo Hoarding Campaign',
            IsActive = true
        );
        insert camp;

        UNEnquiryDTO dto = new UNEnquiryDTO();
        dto.submissionKey = 'SUB-CAMP-001';
        dto.fullName = 'Vignesh Kumar';
        dto.phone = '9840112233';
        dto.email = 'vignesh.k@example.com';
        dto.campaignId = camp.Id;

        Test.startTest();
        UNEnquiryResultDTO res = UNEnquiryController.submitEnquiry(dto);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'Submission should succeed');
        List<CampaignMember> cms = [
            SELECT Id, CampaignId, LeadId, Status 
            FROM CampaignMember 
            WHERE CampaignId = :camp.Id
        ];
        Assert.areEqual(1, cms.size(), 'Should create a CampaignMember linking Lead to Campaign');
        Assert.areEqual('Responded', cms[0].Status);
    }
}