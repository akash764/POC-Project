import { LightningElement, track, wire } from 'lwc';
import getFeaturedVideoTestimonials from '@salesforce/apex/UNReviewController.getFeaturedVideoTestimonials';

export default class UnVideoTestimonials extends LightningElement {
    @track videoItems = [];
    @track isLoading = true;
    @track activeVideoId = '';
    @track activeVideoTitle = '';

    @wire(getFeaturedVideoTestimonials)
    wiredVideos({ error, data }) {
        this.isLoading = false;
        if (data && data.length > 0) {
            this.videoItems = data;
        } else if (error) {
            console.warn('Error loading video testimonials:', error);
            this.videoItems = [];
        }
    }

    get videoList() {
        if (!this.videoItems || this.videoItems.length === 0) return [];
        return this.videoItems.map(vid => {
            const videoId = vid.videoId || 'LXb3EKWsInQ';
            // High quality YouTube thumbnail URL
            const thumb = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
            return {
                ...vid,
                videoId: videoId,
                thumbnailUrl: thumb
            };
        });
    }

    get embedUrl() {
        if (!this.activeVideoId) return '';
        return `https://www.youtube-nocookie.com/embed/${this.activeVideoId}?autoplay=1&rel=0&modestbranding=1`;
    }

    handleOpenVideo(event) {
        const vId = event.currentTarget.dataset.videoid;
        const vTitle = event.currentTarget.dataset.title;
        if (vId) {
            this.activeVideoId = vId;
            this.activeVideoTitle = vTitle || 'Customer Testimonial';
        }
    }

    handleCloseVideo() {
        this.activeVideoId = '';
        this.activeVideoTitle = '';
    }

    handleModalClick(event) {
        // Prevent clicking inside modal from closing it
        event.stopPropagation();
    }
}