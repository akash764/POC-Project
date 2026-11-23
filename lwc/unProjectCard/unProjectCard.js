import { LightningElement, api, track } from 'lwc';

const TYPE_FALLBACK_IMAGES = {
    commercial: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
    villa: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    apartment: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80'
};

const AMENITY_TYPE_ICONS = {
    'swimming pool': '🏊',
    'clubhouse': '🏛️',
    'fitness gym': '🏋️',
    'sports & courts': '🎾',
    'kids play area': '🛝',
    'landscaped gardens': '🌳',
    'rooftop lounge': '🌇',
    'ev charging bays': '⚡',
    '24/7 smart security': '🛡️',
    'co-working space': '💼',
    'other': '✨'
};

export default class UnProjectCard extends LightningElement {
    @api project = {};
    @track useFallback = false;

    get imageSource() {
        if (!this.useFallback && this.project && this.project.brochureContentKey) {
            const key = this.project.brochureContentKey.trim();
            if (key.startsWith('http://') || key.startsWith('https://') || key.startsWith('/')) {
                return key;
            }
            return `/cms/delivery/media/${key}`;
        }

        const pt = (this.project?.projectType || '').toLowerCase();
        if (pt.includes('commercial')) return TYPE_FALLBACK_IMAGES.commercial;
        if (pt.includes('villa')) return TYPE_FALLBACK_IMAGES.villa;
        return TYPE_FALLBACK_IMAGES.apartment;
    }

    handleImageError(event) {
        if (!this.useFallback) {
            this.useFallback = true;
            const pt = (this.project?.projectType || '').toLowerCase();
            let fallback = TYPE_FALLBACK_IMAGES.apartment;
            if (pt.includes('commercial')) fallback = TYPE_FALLBACK_IMAGES.commercial;
            if (pt.includes('villa')) fallback = TYPE_FALLBACK_IMAGES.villa;
            if (event && event.target) {
                event.target.src = fallback;
            }
        }
    }

    get hasRibbonStatus() {
        return Boolean(this.project && this.project.status);
    }

    get ribbonLabel() {
        if (!this.project || !this.project.status) return '';
        const s = this.project.status.toUpperCase();
        if (s.includes('NEW LAUNCH')) return 'NEW LAUNCH';
        if (s.includes('READY TO MOVE')) return 'READY TO MOVE-IN';
        if (s.includes('HANDING OVER')) return 'HANDING OVER SOON';
        if (s.includes('UNDER CONSTRUCTION')) return 'UNDER CONSTRUCTION';
        if (s.includes('ONGOING')) return 'ONGOING';
        return s;
    }

    get ribbonClass() {
        const s = (this.project?.status || '').toLowerCase();
        let colorModifier = 'ribbon-new-launch';
        if (s.includes('ready to move')) colorModifier = 'ribbon-ready-move';
        else if (s.includes('handing over')) colorModifier = 'ribbon-handing-over';
        else if (s.includes('under construction')) colorModifier = 'ribbon-under-construction';
        else if (s.includes('ongoing')) colorModifier = 'ribbon-ongoing';
        return `un-corner-ribbon ${colorModifier}`;
    }

    get projectTypeBadge() {
        const pt = (this.project?.projectType || '').toLowerCase();
        if (pt.includes('commercial')) return '🏢 Commercial Hub';
        if (pt.includes('villa')) return '🏡 Luxury Villa Estate';
        return '🏢 Luxury Residences';
    }

    get locationBadge() {
        return this.project?.city || (this.project?.state ? this.project.state : 'South India');
    }

    get projectTagline() {
        const pt = (this.project?.projectType || '').toLowerCase();
        const name = (this.project?.name || '').toLowerCase();
        if (name.includes('horizon') || pt.includes('commercial')) {
            return 'Innovative workspace for a growing tomorrow.';
        }
        if (name.includes('palm') || pt.includes('villa')) {
            return 'Your private paradise in the heart of the city.';
        }
        return 'Modern living. Timeless comfort.';
    }

    get phaseCountLabel() {
        const count = this.project?.totalPhases || this.project?.totalApartments || 0;
        const pt = (this.project?.projectType || '').toLowerCase();
        if (pt.includes('villa')) return `🏡 ${count} Enclaves`;
        if (pt.includes('commercial')) return `🏬 ${count} Wings`;
        return `🏗️ ${count} Towers`;
    }

    get formattedStartingPrice() {
        if (this.project && this.project.startingPrice) {
            const price = this.project.startingPrice;
            if (price >= 10000000) {
                return `₹ ${(price / 10000000).toFixed(2)} Cr*`;
            } else if (price >= 100000) {
                return `₹ ${(price / 100000).toFixed(2)} Lacs*`;
            }
            return `₹ ${price.toLocaleString('en-IN')}*`;
        }
        return 'Price On Request';
    }

    get formattedBhkOptions() {
        const pt = (this.project?.projectType || '').toLowerCase();
        if (pt.includes('commercial')) {
            if (this.project && this.project.unitTypeOptions && this.project.unitTypeOptions.length > 0) {
                return this.project.unitTypeOptions.join(', ');
            }
            return 'Offices & Retail Suites';
        }
        if (this.project && this.project.bhkOptions && this.project.bhkOptions.length > 0) {
            return this.project.bhkOptions.join(', ');
        }
        return pt.includes('villa') ? '3, 4 & 5 BHK Villas' : '1, 2 & 3 BHK';
    }

    get inventoryStatusText() {
        if (!this.project) return 'Inquire for Units';
        if (this.project.availableUnits && this.project.availableUnits > 0) {
            return `🟢 ${this.project.availableUnits} Available`;
        }
        return '🟡 Fully Booked';
    }

    get hasAmenities() {
        return Boolean(this.project && this.project.amenities && this.project.amenities.length > 0);
    }

    get totalAmenitiesCount() {
        return (this.project && this.project.amenities) ? this.project.amenities.length : 0;
    }

    get cardAmenities() {
        if (!this.hasAmenities) return [];
        return this.project.amenities.slice(0, 3).map(a => {
            const typeKey = (a.amenityType || 'other').toLowerCase();
            return {
                id: a.id || a.name,
                name: a.name,
                icon: AMENITY_TYPE_ICONS[typeKey] || '✨'
            };
        });
    }

    get hasMoreAmenities() {
        return this.totalAmenitiesCount > 3;
    }

    get remainingAmenitiesCount() {
        return Math.max(0, this.totalAmenitiesCount - 3);
    }

    handleViewDetails(event) {
        if (event) event.stopPropagation();
        this.dispatchEvent(new CustomEvent('viewdetails', {
            detail: {
                projectId: this.project.id
            },
            bubbles: true,
            composed: true
        }));
    }

    handleEnquire(event) {
        if (event) event.stopPropagation();
        this.dispatchEvent(new CustomEvent('enquire', {
            detail: {
                projectId: this.project.id,
                projectName: this.project.name
            },
            bubbles: true,
            composed: true
        }));
    }
}