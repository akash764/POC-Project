import { LightningElement, api, track } from 'lwc';

const SLIDES = [
    {
        id: 'slide-apartments',
        category: 'Residential Apartments',
        icon: '🏢',
        title: 'Our Portfolio of Developments',
        subtitle: 'Explore meticulously planned residential high-rises, penthouses, and sky suites across South India\'s prime urban corridors.',
        bgImage: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1920&q=85'
    },
    {
        id: 'slide-villas',
        category: 'Gated Villa Estates',
        icon: '🏡',
        title: 'Architectural Sanctuaries & Private Enclaves',
        subtitle: 'Discover private gated estates featuring infinity pools, landscaped gardens, and timeless contemporary craftsmanship.',
        bgImage: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1920&q=85'
    },
    {
        id: 'slide-commercial',
        category: 'Grade-A Commercial Parks',
        icon: '🏬',
        title: 'Next-Generation Corporate & Tech Spaces',
        subtitle: 'Grade-A LEED certified business parks, high-street retail promenades, and executive office suites in prime central districts.',
        bgImage: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1920&q=85'
    }
];

const AUTO_PLAY_INTERVAL = 5500; // 5.5 seconds per slide

export default class UnHeroBanner extends LightningElement {
    @api title = '';
    @api subtitle = '';
    @api badgeText = '';
    @api primaryActionLabel = 'Explore Our Projects';
    @api secondaryActionLabel = '';
    @api bgImageUrl = '';
    @api height = 'large';

    @track currentSlideIndex = 0;
    autoPlayTimer = null;
    isPaused = false;

    connectedCallback() {
        this.startAutoPlay();
    }

    disconnectedCallback() {
        this.stopAutoPlay();
    }

    startAutoPlay() {
        this.stopAutoPlay();
        this.autoPlayTimer = setInterval(() => {
            if (!this.isPaused) {
                this.nextSlide();
            }
        }, AUTO_PLAY_INTERVAL);
    }

    stopAutoPlay() {
        if (this.autoPlayTimer) {
            clearInterval(this.autoPlayTimer);
            this.autoPlayTimer = null;
        }
    }

    nextSlide() {
        this.currentSlideIndex = (this.currentSlideIndex + 1) % SLIDES.length;
    }

    handleDotClick(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (!isNaN(index) && index >= 0 && index < SLIDES.length) {
            this.currentSlideIndex = index;
            // Restart timer so the user has the full interval after manual selection
            this.startAutoPlay();
        }
    }

    handleMouseEnter() {
        this.isPaused = true;
    }

    handleMouseLeave() {
        this.isPaused = false;
    }

    get currentSlide() {
        return SLIDES[this.currentSlideIndex] || SLIDES[0];
    }

    get slideItems() {
        return SLIDES.map((slide, idx) => {
            const isActive = idx === this.currentSlideIndex;
            // If parent provided custom bgImageUrl on slide 0, honor it
            const img = (idx === 0 && this.bgImageUrl) ? this.bgImageUrl : slide.bgImage;
            return {
                id: slide.id,
                bgClass: isActive ? 'un-hero-slide-bg is-active' : 'un-hero-slide-bg',
                style: `background-image: url('${img}');`,
                ariaHidden: !isActive
            };
        });
    }

    get dotIndicators() {
        return SLIDES.map((slide, idx) => {
            const isActive = idx === this.currentSlideIndex;
            return {
                index: idx,
                cssClass: isActive ? 'un-hero-dot active' : 'un-hero-dot',
                isActive: isActive,
                ariaLabel: `Navigate to slide ${idx + 1}: ${slide.category}`,
                title: slide.category
            };
        });
    }

    get displayTitle() {
        // If parent explicitly passed a title (e.g. from a page wrapper), use it for slide 0, or use slide title
        if (this.currentSlideIndex === 0 && this.title) {
            return this.title;
        }
        return this.currentSlide.title;
    }

    get displaySubtitle() {
        if (this.currentSlideIndex === 0 && this.subtitle) {
            return this.subtitle;
        }
        return this.currentSlide.subtitle;
    }

    get bannerClass() {
        return `un-hero-banner un-hero-${this.height}`;
    }

    handlePrimaryAction() {
        this.dispatchEvent(new CustomEvent('primaryaction', {
            bubbles: true,
            composed: true
        }));
    }

    handleSecondaryAction() {
        this.dispatchEvent(new CustomEvent('secondaryaction', {
            bubbles: true,
            composed: true
        }));
    }
}