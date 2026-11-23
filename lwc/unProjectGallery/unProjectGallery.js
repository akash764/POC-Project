import { LightningElement, api, track } from 'lwc';

const CURATED_GALLERY_IMAGES = [
    {
        id: '1',
        title: 'Architectural Elevation',
        category: 'Exterior Facade',
        fallbackUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80'
    },
    {
        id: '2',
        title: 'Grand Entrance Lobby',
        category: 'Arrival Experience',
        fallbackUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80'
    },
    {
        id: '3',
        title: 'Sample Luxury Residence',
        category: 'Interior Living Space',
        fallbackUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80'
    },
    {
        id: '4',
        title: 'Clubhouse & Horizon Pool',
        category: 'Amenities & Recreation',
        fallbackUrl: 'https://images.unsplash.com/photo-1577495508048-b635879837f1?auto=format&fit=crop&w=1200&q=80'
    }
];

export default class UnProjectGallery extends LightningElement {
    @api brochureContentKey = '';
    @api projectName = 'UrbanNest Project';
    @api amenities = [];

    @track selectedItemId = '1';
    @track activeImageFailed = false;

    get galleryItems() {
        const items = [];

        // 1. Project Hero Cover
        let coverUrl = CURATED_GALLERY_IMAGES[0].fallbackUrl;
        if (this.brochureContentKey) {
            const key = this.brochureContentKey.trim();
            if (key.startsWith('http://') || key.startsWith('https://') || key.startsWith('/')) {
                coverUrl = key;
            } else {
                coverUrl = `/cms/delivery/media/${key}`;
            }
        }
        items.push({
            id: '1',
            title: `${this.projectName} Exterior Elevation`,
            category: 'Exterior Facade',
            url: coverUrl,
            thumbClass: this.selectedItemId === '1' ? 'un-thumb-btn is-active' : 'un-thumb-btn'
        });

        // 2. Real Child Amenities if configured
        if (this.amenities && this.amenities.length > 0) {
            this.amenities.forEach((a, idx) => {
                const itemId = String(idx + 2);
                let photoUrl = '';
                if (a.photoContentKey) {
                    const key = a.photoContentKey.trim();
                    if (key.startsWith('http://') || key.startsWith('https://') || key.startsWith('/')) {
                        photoUrl = key;
                    } else {
                        photoUrl = `/cms/delivery/media/${key}`;
                    }
                } else {
                    photoUrl = CURATED_GALLERY_IMAGES[(idx % 3) + 1]?.fallbackUrl || CURATED_GALLERY_IMAGES[1].fallbackUrl;
                }

                items.push({
                    id: itemId,
                    title: a.name || `Amenity ${idx + 1}`,
                    category: a.amenityType || 'Project Amenity',
                    url: photoUrl,
                    thumbClass: this.selectedItemId === itemId ? 'un-thumb-btn is-active' : 'un-thumb-btn'
                });
            });
        } else {
            // Fallback curated images if no child amenities added yet
            for (let i = 1; i < CURATED_GALLERY_IMAGES.length; i++) {
                const cur = CURATED_GALLERY_IMAGES[i];
                items.push({
                    ...cur,
                    url: cur.fallbackUrl,
                    thumbClass: this.selectedItemId === cur.id ? 'un-thumb-btn is-active' : 'un-thumb-btn'
                });
            }
        }

        return items;
    }

    get activeItem() {
        return this.galleryItems.find(item => item.id === this.selectedItemId) || this.galleryItems[0];
    }

    get activeImageUrl() {
        if (this.activeImageFailed) {
            const fallback = CURATED_GALLERY_IMAGES.find(i => i.id === this.selectedItemId);
            return fallback ? fallback.fallbackUrl : CURATED_GALLERY_IMAGES[0].fallbackUrl;
        }
        return this.activeItem.url;
    }

    get activeImageTitle() {
        return `${this.projectName} - ${this.activeItem.title}`;
    }

    get activeImageCategory() {
        return this.activeItem.category;
    }

    handleThumbClick(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedItemId = id;
        this.activeImageFailed = false;
    }

    handleActiveImageError() {
        this.activeImageFailed = true;
    }
}