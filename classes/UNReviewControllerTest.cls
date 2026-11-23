/**
 * @description Comprehensive unit test suite for UNReviewController and UNReviewService.
 */
@IsTest
private class UNReviewControllerTest {

    @TestSetup
    static void setupData() {
        Project__c p = new Project__c(
            Name = 'Grand Heights Test',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Status__c = 'Active'
        );
        insert p;

        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Property_Review__c.getRecordTypeInfosByDeveloperName();
        Id videoRtId = rtMap.containsKey('Marketing_Video_Testimonial') ? rtMap.get('Marketing_Video_Testimonial').getRecordTypeId() : null;
        Id writtenRtId = rtMap.containsKey('Customer_Written_Review') ? rtMap.get('Customer_Written_Review').getRecordTypeId() : null;

        List<Property_Review__c> reviews = new List<Property_Review__c>();

        // 1. Featured Video Review
        Property_Review__c vidReview = new Property_Review__c(
            Project__c = p.Id,
            RecordTypeId = videoRtId,
            Reviewer_Name__c = 'Karthik Family',
            Review_Type__c = 'Video Testimonial',
            Video_URL__c = 'https://www.youtube.com/watch?v=LXb3EKWsInQ',
            Rating__c = 5,
            Review_Title__c = 'Amazing Living Experience',
            Quote_or_Feedback__c = 'We love our new apartment and the wonderful community.',
            Is_Featured_Home__c = true,
            Status__c = 'Approved',
            Verified_Visitor__c = true
        );
        reviews.add(vidReview);

        // 2. Approved Written Review
        Property_Review__c writReview = new Property_Review__c(
            Project__c = p.Id,
            RecordTypeId = writtenRtId,
            Reviewer_Name__c = 'Ramesh Kumar',
            Review_Type__c = 'Written Review',
            Rating__c = 5,
            Review_Title__c = 'Punctual site visit',
            Quote_or_Feedback__c = 'Smooth walkthrough and transparent pricing.',
            Is_Featured_Home__c = false,
            Status__c = 'Approved',
            Verified_Visitor__c = true
        );
        reviews.add(writReview);

        insert reviews;
    }

    @IsTest
    static void testGetFeaturedVideoTestimonials() {
        Test.startTest();
        List<UNPropertyReviewDTO> vids = UNReviewController.getFeaturedVideoTestimonials();
        Test.stopTest();

        System.assertNotEquals(null, vids, 'Should return video testimonials list');
        System.assert(vids.size() >= 1, 'Should contain at least 1 video testimonial');
        System.assertEquals('LXb3EKWsInQ', vids[0].videoId, 'Should extract correct YouTube ID');
    }

    @IsTest
    static void testGetProjectReviews() {
        Project__c p = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = UNReviewController.getProjectReviews(p.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
        System.assert(result.containsKey('reviews'), 'Response should contain reviews');
        System.assert(result.containsKey('averageRating'), 'Response should contain average rating');

        List<UNPropertyReviewDTO> revList = (List<UNPropertyReviewDTO>) result.get('reviews');
        System.assertEquals(1, revList.size(), 'Should only return the written review and exclude video testimonials');
        System.assertEquals('Ramesh Kumar', revList[0].reviewerName, 'Should match written reviewer name');
        System.assertEquals('Written Review', revList[0].reviewType, 'Review type must be Written Review');
    }

    @IsTest
    static void testSubmitProjectReviewSuccess() {
        Project__c p = [SELECT Id FROM Project__c LIMIT 1];

        UNPropertyReviewDTO input = new UNPropertyReviewDTO();
        input.projectId = p.Id;
        input.reviewerName = 'Suresh Babu';
        input.reviewType = 'Written Review';
        input.rating = 5;
        input.reviewTitle = 'Excellent Clubhouse';
        input.feedback = 'The sports courts and pool are genuinely world class.';
        input.customerLocation = 'Chennai';

        Test.startTest();
        UNReviewResultDTO res = UNReviewController.submitProjectReview(input);
        Test.stopTest();

        System.assertEquals(true, res.isSuccess, 'Submission should succeed');
        System.assertNotEquals(null, res.reviewId, 'Should return created review ID');

        Property_Review__c insertedRev = [
            SELECT Id, Status__c, Reviewer_Name__c 
            FROM Property_Review__c 
            WHERE Id = :res.reviewId
        ];
        System.assertEquals('Pending Moderation', insertedRev.Status__c, 'Must default to Pending Moderation');
    }

    @IsTest
    static void testSubmitProjectReviewValidation() {
        Test.startTest();
        UNReviewResultDTO resNull = UNReviewController.submitProjectReview(null);
        UNPropertyReviewDTO emptyInput = new UNPropertyReviewDTO();
        UNReviewResultDTO resMissing = UNReviewController.submitProjectReview(emptyInput);
        Test.stopTest();

        System.assertEquals(false, resNull.isSuccess, 'Null input should fail');
        System.assertEquals(false, resMissing.isSuccess, 'Empty input should fail');
    }

    @IsTest
    static void testExtractYouTubeIdVariations() {
        System.assertEquals('abc123xyz89', UNReviewService.extractYouTubeId('abc123xyz89'));
        System.assertEquals('LXb3EKWsInQ', UNReviewService.extractYouTubeId('https://youtu.be/LXb3EKWsInQ?si=test'));
        System.assertEquals('ScMzIvxBSi4', UNReviewService.extractYouTubeId('https://www.youtube.com/watch?v=ScMzIvxBSi4&t=10s'));
        System.assertEquals('dQw4w9WgXcQ', UNReviewService.extractYouTubeId('https://www.youtube.com/embed/dQw4w9WgXcQ'));
        System.assertEquals('', UNReviewService.extractYouTubeId(null));
    }
}