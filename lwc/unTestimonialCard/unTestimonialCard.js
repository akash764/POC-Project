import { LightningElement, api } from 'lwc';

export default class UnTestimonialCard extends LightningElement {
    @api quote = 'UrbanNest delivered beyond our highest expectations. The architectural finesse, ventilation, and transparency throughout the buying process were unparalleled.';
    @api authorName = 'Dr. Anand Ramanathan';
    @api projectName = 'Urban Serenity, Chennai';

    get initials() {
        if (!this.authorName) return 'UN';
        return this.authorName
            .split(' ')
            .filter(p => !p.startsWith('Dr.') && !p.startsWith('Mr.') && !p.startsWith('Mrs.'))
            .map(p => p[0])
            .slice(0, 2)
            .join('')
            .toUpperCase() || 'UN';
    }
}