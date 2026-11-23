import { LightningElement, api, track, wire } from 'lwc';
import getProjectReviews from '@salesforce/apex/UNReviewController.getProjectReviews';
import submitProjectReview from '@salesforce/apex/UNReviewController.submitProjectReview';
import { refreshApex } from '@salesforce/apex';

export default class UnProjectReviews extends LightningElement {
    @api projectId = '';
    @api projectName = 'This Project';

    @track reviews = [];
    @track averageRating = 5.0;
    @track totalCount = 0;
    @track isLoading = true;

    // Modal state
    @track isModalOpen = false;
    @track isSubmitting = false;
    @track isSubmitted = false;
    @track submitSuccessMessage = '';
    @track serverErrorMessage = '';

    // Form inputs
    @track formRating = 5;
    @track formName = '';
    @track formLocation = '';
    @track formTitle = '';
    @track formFeedback = '';
    @track formErrors = {};

    wiredReviewsResult;

    @wire(getProjectReviews, { projectId: '$projectId' })
    wiredReviews(result) {
        this.wiredReviewsResult = result;
        this.isLoading = false;
        if (result.data) {
            const raw = result.data.reviews || [];
            // Project reviews page is strictly for Customer Written Reviews
            this.reviews = raw.filter(r => r.reviewType !== 'Video Testimonial' && !r.videoId);
            this.totalCount = this.reviews.length;
            if (this.totalCount > 0) {
                const sum = this.reviews.reduce((acc, r) => acc + (r.rating || 5), 0);
                this.averageRating = Number((sum / this.totalCount).toFixed(1));
            } else {
                this.averageRating = 0;
            }
        } else if (result.error) {
            console.warn('Error fetching project reviews:', result.error);
            this.reviews = [];
            this.totalCount = 0;
            this.averageRating = 0;
        }
    }

    get hasReviews() {
        return this.reviews && this.reviews.length > 0;
    }

    get formattedAverageRating() {
        return (this.averageRating && this.averageRating > 0) ? this.averageRating.toFixed(1) : '5.0';
    }

    get reviewCountText() {
        if (!this.totalCount || this.totalCount === 0) {
            return 'No verified reviews yet';
        }
        return `Based on ${this.totalCount} verified ${this.totalCount === 1 ? 'experience' : 'experiences'}`;
    }

    get reviewList() {
        if (!this.reviews || this.reviews.length === 0) return [];
        return this.reviews
            .filter(r => r.reviewType !== 'Video Testimonial' && !r.videoId)
            .map(r => {
                const starsCount = (r.rating && r.rating >= 1 && r.rating <= 5) ? r.rating : 5;
                const starsArr = [];
                for (let i = 1; i <= starsCount; i++) {
                    starsArr.push({ id: `star-${r.id || Math.random()}-${i}` });
                }

                // Generate user initials
                const name = r.reviewerName || 'Visitor';
                const parts = name.trim().split(/\s+/);
                const initials = parts.length > 1
                    ? (parts[0][0] + parts[1][0]).toUpperCase()
                    : (name[0] || 'U').toUpperCase();

                return {
                    ...r,
                    stars: starsArr,
                    initials: initials,
                    feedback: r.feedback || 'Verified project visit experience.',
                    customerLocation: r.customerLocation || 'Verified Site Visitor',
                    formattedDate: r.formattedDate || 'Recently'
                };
            });
    }

    get starPickerOptions() {
        return [
            { value: 1, label: '1 Star - Poor', cssClass: this.formRating >= 1 ? 'un-picker-star active' : 'un-picker-star' },
            { value: 2, label: '2 Stars - Fair', cssClass: this.formRating >= 2 ? 'un-picker-star active' : 'un-picker-star' },
            { value: 3, label: '3 Stars - Average', cssClass: this.formRating >= 3 ? 'un-picker-star active' : 'un-picker-star' },
            { value: 4, label: '4 Stars - Good', cssClass: this.formRating >= 4 ? 'un-picker-star active' : 'un-picker-star' },
            { value: 5, label: '5 Stars - Excellent', cssClass: this.formRating >= 5 ? 'un-picker-star active' : 'un-picker-star' }
        ];
    }

    get selectedRatingLabel() {
        const labels = {
            1: '1 Star (Poor)',
            2: '2 Stars (Fair)',
            3: '3 Stars (Average)',
            4: '4 Stars (Good)',
            5: '5 Stars (Excellent)'
        };
        return labels[this.formRating] || '5 Stars';
    }

    handleSelectRating(event) {
        const val = parseInt(event.currentTarget.dataset.val, 10);
        if (!isNaN(val) && val >= 1 && val <= 5) {
            this.formRating = val;
        }
    }

    handleOpenModal() {
        this.isModalOpen = true;
        this.isSubmitted = false;
        this.serverErrorMessage = '';
        this.formErrors = {};
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.resetForm();
    }

    handleModalClick(event) {
        event.stopPropagation();
    }

    handleNameChange(e) {
        this.formName = e.target.value;
        this.clearFieldError('name');
    }

    handleLocationChange(e) {
        this.formLocation = e.target.value;
    }

    handleTitleChange(e) {
        this.formTitle = e.target.value;
    }

    handleFeedbackChange(e) {
        this.formFeedback = e.target.value;
        this.clearFieldError('feedback');
    }

    clearFieldError(field) {
        if (this.formErrors[field]) {
            this.formErrors = { ...this.formErrors, [field]: null };
        }
    }

    validateInputs() {
        const errs = {};
        if (!this.formName || !this.formName.trim()) {
            errs.name = 'Please enter your name.';
        }
        if (!this.formFeedback || !this.formFeedback.trim()) {
            errs.feedback = 'Please provide your review feedback.';
        }
        this.formErrors = errs;
        return Object.keys(errs).length === 0;
    }

    async handleSubmitReview(event) {
        event.preventDefault();
        this.serverErrorMessage = '';

        if (!this.validateInputs()) {
            return;
        }

        this.isSubmitting = true;

        const payload = {
            projectId: this.projectId,
            reviewerName: this.formName.trim(),
            rating: this.formRating,
            reviewTitle: this.formTitle ? this.formTitle.trim() : 'Site Visit Review',
            feedback: this.formFeedback.trim(),
            customerLocation: this.formLocation ? this.formLocation.trim() : 'Chennai',
            reviewType: 'Written Review'
        };

        try {
            const result = await submitProjectReview({ reviewInput: payload });
            if (result && result.isSuccess) {
                this.isSubmitted = true;
                this.submitSuccessMessage = result.message || 'Thank you! Your review has been submitted for moderation and will appear on the website shortly.';
                // Refresh reviews if possible
                if (this.wiredReviewsResult) {
                    refreshApex(this.wiredReviewsResult);
                }
            } else {
                this.serverErrorMessage = (result && result.message) ? result.message : 'Unable to submit review.';
            }
        } catch (err) {
            console.error('Error submitting review:', err);
            this.serverErrorMessage = (err && err.body && err.body.message) ? err.body.message : 'Submission failed. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }

    resetForm() {
        this.formRating = 5;
        this.formName = '';
        this.formLocation = '';
        this.formTitle = '';
        this.formFeedback = '';
        this.formErrors = {};
        this.serverErrorMessage = '';
    }
}