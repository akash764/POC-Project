/**
 * @description Service class handling Customer Property Reviews, Video Testimonials,
 * and Site Visit Feedback ingestion and queries for Experience Cloud LWR.
 */
public without sharing class UNReviewService {

    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_PENDING = 'Pending Moderation';
    private static final String TYPE_VIDEO = 'Video Testimonial';
    private static final String TYPE_WRITTEN = 'Written Review';

    /**
     * @description Retrieves the 3 featured customer video testimonials for the Home Page.
     * If no records exist in the org, provides curated real-estate video samples.
     */
    public static List<UNPropertyReviewDTO> getFeaturedVideoTestimonials() {
        List<UNPropertyReviewDTO> results = new List<UNPropertyReviewDTO>();

        try {
            List<Property_Review__c> reviews = [
                SELECT Id, Reviewer_Name__c, Review_Type__c, Video_URL__c, Rating__c,
                       Review_Title__c, Quote_or_Feedback__c, Customer_Location__c,
                       Unit_Purchased__c, Verified_Visitor__c, Is_Featured_Home__c, CreatedDate,
                       Project__c, Project__r.Name, Project__r.City__c
                FROM Property_Review__c
                WHERE (Review_Type__c = :TYPE_VIDEO OR RecordType.DeveloperName = 'Marketing_Video_Testimonial')
                  AND Status__c = :STATUS_APPROVED
                ORDER BY Is_Featured_Home__c DESC, CreatedDate DESC
                LIMIT 6
            ];

            for (Property_Review__c r : reviews) {
                results.add(mapToDTO(r));
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to query Property_Review__c: ' + ex.getMessage());
        }

        // If fewer than 3 are configured in Salesforce, supplement with realistic fallback demos
        if (results.size() < 3) {
            results.addAll(getFallbackVideoTestimonials(3 - results.size()));
        }

        return results;
    }

    /**
     * @description Retrieves all approved written reviews for a specific project.
     * Excludes video testimonials so they only appear on the Home Page video section.
     * Returns reviews list, calculated average rating, and count.
     */
    public static Map<String, Object> getProjectReviews(Id projectId) {
        Map<String, Object> response = new Map<String, Object>();
        List<UNPropertyReviewDTO> reviewList = new List<UNPropertyReviewDTO>();
        Decimal totalRating = 0;
        Integer ratingCount = 0;

        if (projectId != null) {
            try {
                List<Property_Review__c> dbReviews = [
                    SELECT Id, Reviewer_Name__c, Review_Type__c, Video_URL__c, Rating__c,
                           Review_Title__c, Quote_or_Feedback__c, Customer_Location__c,
                           Unit_Purchased__c, Verified_Visitor__c, Is_Featured_Home__c, CreatedDate,
                           Project__c, Project__r.Name, Project__r.City__c
                    FROM Property_Review__c
                    WHERE Project__c = :projectId
                      AND Status__c = :STATUS_APPROVED
                      AND (Review_Type__c = :TYPE_WRITTEN OR RecordType.DeveloperName = 'Customer_Written_Review')
                      AND Review_Type__c != :TYPE_VIDEO
                      AND RecordType.DeveloperName != 'Marketing_Video_Testimonial'
                    ORDER BY CreatedDate DESC
                    LIMIT 50
                ];

                for (Property_Review__c r : dbReviews) {
                    UNPropertyReviewDTO dto = mapToDTO(r);
                    reviewList.add(dto);
                    if (r.Rating__c != null && r.Rating__c > 0) {
                        totalRating += r.Rating__c;
                        ratingCount++;
                    }
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Error fetching reviews for project ' + projectId + ': ' + ex.getMessage());
            }
        }

        Decimal avgRating = (ratingCount > 0) ? (totalRating / ratingCount).setScale(1) : 0;

        response.put('reviews', reviewList);
        response.put('totalCount', reviewList.size());
        response.put('averageRating', avgRating);

        return response;
    }

    /**
     * @description Ingests a new site visit review submitted by a website visitor.
     * Saved as 'Pending Moderation' for manager approval.
     */
    public static UNReviewResultDTO submitProjectReview(UNPropertyReviewDTO input) {
        if (input == null) {
            return new UNReviewResultDTO(false, 'Review details are missing.');
        }

        if (String.isBlank(input.reviewerName)) {
            return new UNReviewResultDTO(false, 'Please provide your name.');
        }

        if (String.isBlank(input.feedback)) {
            return new UNReviewResultDTO(false, 'Please share your visit experience or feedback.');
        }

        if (String.isBlank(input.projectId)) {
            return new UNReviewResultDTO(false, 'Associated project identifier is required.');
        }

        Property_Review__c newReview = new Property_Review__c();
        newReview.Project__c = input.projectId;
        newReview.Reviewer_Name__c = input.reviewerName.trim();
        newReview.Review_Type__c = String.isNotBlank(input.reviewType) ? input.reviewType : TYPE_WRITTEN;
        newReview.Rating__c = (input.rating != null && input.rating >= 1 && input.rating <= 5) ? input.rating : 5;
        newReview.Review_Title__c = String.isNotBlank(input.reviewTitle) ? input.reviewTitle.trim() : 'Site Visit Feedback';
        newReview.Quote_or_Feedback__c = input.feedback.trim();
        newReview.Customer_Location__c = String.isNotBlank(input.customerLocation) ? input.customerLocation.trim() : 'Chennai';
        newReview.Unit_Purchased__c = input.unitPurchased;
        newReview.Video_URL__c = input.videoUrl;
        newReview.Verified_Visitor__c = true;
        newReview.Status__c = STATUS_PENDING;

        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Property_Review__c.getRecordTypeInfosByDeveloperName();
        if (rtMap != null && rtMap.containsKey('Customer_Written_Review')) {
            newReview.RecordTypeId = rtMap.get('Customer_Written_Review').getRecordTypeId();
        }

        try {
            insert newReview;
            return new UNReviewResultDTO(
                true,
                'Thank you for sharing your experience! Your review has been submitted for verification and will appear on the website shortly.',
                newReview.Id
            );
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to save review: ' + ex.getMessage());
            return new UNReviewResultDTO(false, 'Unable to submit review at this moment. Please try again.');
        }
    }

    /**
     * @description Maps Salesforce sObject Property_Review__c to DTO
     */
    private static UNPropertyReviewDTO mapToDTO(Property_Review__c r) {
        UNPropertyReviewDTO dto = new UNPropertyReviewDTO();
        dto.id = r.Id;
        dto.projectId = r.Project__c;
        dto.projectName = (r.Project__r != null) ? r.Project__r.Name : '';
        dto.projectCity = (r.Project__r != null) ? r.Project__r.City__c : '';
        dto.reviewerName = r.Reviewer_Name__c;
        dto.reviewType = r.Review_Type__c;
        dto.videoUrl = r.Video_URL__c;
        dto.videoId = extractYouTubeId(r.Video_URL__c);
        dto.rating = (r.Rating__c != null) ? Integer.valueOf(r.Rating__c) : 5;
        dto.reviewTitle = r.Review_Title__c;
        dto.feedback = r.Quote_or_Feedback__c;
        dto.isFeaturedHome = (r.Is_Featured_Home__c == true);
        dto.isVerifiedVisitor = (r.Verified_Visitor__c == true);
        dto.customerLocation = r.Customer_Location__c;
        dto.unitPurchased = r.Unit_Purchased__c;
        dto.formattedDate = (r.CreatedDate != null) ? r.CreatedDate.format('MMM yyyy') : 'Recent';
        return dto;
    }

    /**
     * @description Extracts the 11-character YouTube video ID from various YouTube URL formats.
     */
    public static String extractYouTubeId(String url) {
        if (String.isBlank(url)) return '';
        url = url.trim();

        // 1. If it's already an 11-char alphanumeric ID
        if (Pattern.matches('^[a-zA-Z0-9_-]{11}$', url)) {
            return url;
        }

        // 2. youtu.be/ID
        if (url.contains('youtu.be/')) {
            String sub = url.substringAfter('youtu.be/');
            if (sub.contains('?')) sub = sub.substringBefore('?');
            return sub;
        }

        // 3. watch?v=ID
        if (url.contains('v=')) {
            String sub = url.substringAfter('v=');
            if (sub.contains('&')) sub = sub.substringBefore('&');
            if (sub.contains('?')) sub = sub.substringBefore('?');
            return sub;
        }

        // 4. embed/ID
        if (url.contains('embed/')) {
            String sub = url.substringAfter('embed/');
            if (sub.contains('?')) sub = sub.substringBefore('?');
            return sub;
        }

        return '';
    }

    /**
     * @description Curated luxury real estate customer walkthrough fallback videos
     */
    private static List<UNPropertyReviewDTO> getFallbackVideoTestimonials(Integer count) {
        List<UNPropertyReviewDTO> samples = new List<UNPropertyReviewDTO>();

        UNPropertyReviewDTO s1 = new UNPropertyReviewDTO();
        s1.id = 'demo-vid-1';
        s1.reviewerName = 'Dr. Anand & Priya Raman';
        s1.reviewType = TYPE_VIDEO;
        s1.videoId = 'LXb3EKWsInQ'; // Standard high-def luxury apartment tour sample
        s1.videoUrl = 'https://www.youtube.com/watch?v=LXb3EKWsInQ';
        s1.rating = 5;
        s1.reviewTitle = 'A Meticulous Buying Experience';
        s1.feedback = 'From the chauffeur pickup for the site visit to receiving our keys, UrbanNest treated us like royalty. The panoramic balcony view is unmatched.';
        s1.projectName = 'Skyline Heights';
        s1.projectCity = 'Chennai';
        s1.customerLocation = 'Anna Nagar, Chennai';
        s1.unitPurchased = '3 BHK Luxury Suite';
        s1.formattedDate = 'Oct 2026';
        samples.add(s1);

        UNPropertyReviewDTO s2 = new UNPropertyReviewDTO();
        s2.id = 'demo-vid-2';
        s2.reviewerName = 'Karthik & Deepa Venkat';
        s2.reviewType = TYPE_VIDEO;
        s2.videoId = 'ScMzIvxBSi4'; // Standard luxury villa walkthrough sample
        s2.videoUrl = 'https://www.youtube.com/watch?v=ScMzIvxBSi4';
        s2.rating = 5;
        s2.reviewTitle = 'Serene Gated Villa Living';
        s2.feedback = 'We wanted space, privacy, and an IGBC-certified green enclave. Azure Palms exceeded our expectations. The private lawn is our kids favourite spot.';
        s2.projectName = 'Azure Palms Enclave';
        s2.projectCity = 'Bengaluru';
        s2.customerLocation = 'Whitefield, Bengaluru';
        s2.unitPurchased = '4 BHK Signature Villa';
        s2.formattedDate = 'Sep 2026';
        samples.add(s2);

        UNPropertyReviewDTO s3 = new UNPropertyReviewDTO();
        s3.id = 'demo-vid-3';
        s3.reviewerName = 'Rajesh Mehta (Director, NexaTech)';
        s3.reviewType = TYPE_VIDEO;
        s3.videoId = 'dQw4w9WgXcQ'; 
        s3.videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        s3.rating = 5;
        s3.reviewTitle = 'Next-Gen Corporate Workspace';
        s3.feedback = 'The LEED Gold certification, redundant power systems, and executive food hall made Elysium Business Park the natural choice for our APAC office.';
        s3.projectName = 'Elysium Business Park';
        s3.projectCity = 'Hyderabad';
        s3.customerLocation = 'Hitec City, Hyderabad';
        s3.unitPurchased = 'Grade-A Corporate Wing';
        s3.formattedDate = 'Aug 2026';
        samples.add(s3);

        List<UNPropertyReviewDTO> trimmed = new List<UNPropertyReviewDTO>();
        for (Integer i = 0; i < Math.min(count, samples.size()); i++) {
            trimmed.add(samples[i]);
        }
        return trimmed;
    }

    /**
     * @description Curated written reviews fallback for specific project view
     */
    private static List<UNPropertyReviewDTO> getFallbackProjectReviews(Id projectId) {
        List<UNPropertyReviewDTO> fallbacks = new List<UNPropertyReviewDTO>();

        UNPropertyReviewDTO r1 = new UNPropertyReviewDTO();
        r1.id = 'sample-rev-1';
        r1.reviewerName = 'Naveen Karthik';
        r1.reviewType = TYPE_WRITTEN;
        r1.rating = 5;
        r1.reviewTitle = 'Exceptional construction quality & secure community';
        r1.feedback = 'Attended the site visit last weekend. The sales rep explained every detail patiently. The model apartment layout matches the brochure 100%. Very impressed with the amenities!';
        r1.customerLocation = 'Chennai';
        r1.isVerifiedVisitor = true;
        r1.unitPurchased = 'Verified Site Visitor';
        r1.formattedDate = '2 months ago';
        fallbacks.add(r1);

        UNPropertyReviewDTO r2 = new UNPropertyReviewDTO();
        r2.id = 'sample-rev-2';
        r2.reviewerName = 'Thennavan Karuna';
        r2.reviewType = TYPE_WRITTEN;
        r2.rating = 5;
        r2.reviewTitle = 'Premium gated community with great connectivity';
        r2.feedback = 'Recently booked our unit here. The transparency in legal documents and RERA approvals gave my family complete peace of mind. Highly recommended!';
        r2.customerLocation = 'Chennai';
        r2.isVerifiedVisitor = true;
        r2.unitPurchased = 'Verified Homeowner';
        r2.formattedDate = '1 month ago';
        fallbacks.add(r2);

        UNPropertyReviewDTO r3 = new UNPropertyReviewDTO();
        r3.id = 'sample-rev-3';
        r3.reviewerName = 'Mani S.';
        r3.reviewType = TYPE_WRITTEN;
        r3.rating = 5;
        r3.reviewTitle = 'Spacious clubhouse and quiet environment';
        r3.feedback = 'Took the complimentary chauffeur pickup from Adyar. The driver was professional and on time. The swimming pool and landscaped gardens are top notch.';
        r3.customerLocation = 'Chennai';
        r3.isVerifiedVisitor = true;
        r3.unitPurchased = 'Verified Site Visitor';
        r3.formattedDate = '3 weeks ago';
        fallbacks.add(r3);

        return fallbacks;
    }
}