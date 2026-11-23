import { LightningElement, track, wire, api } from 'lwc';
import URBANNEST_LOGO from '@salesforce/resourceUrl/UrbanNest_Logo';
import getCompanyContactInfo from '@salesforce/apex/UNProjectController.getCompanyContactInfo';

export default class UnFooter extends LightningElement {
    @api customAddress;
    @api customPhone;
    @api customEmail;

    @track isLogoFallback = false;
    logoUrl = URBANNEST_LOGO;

    contactSettings = {
        address: 'Level 12, Urban Horizon Center, IT Corridor, Chennai — 600096',
        phone: '+91 93636 47520',
        phoneRaw: '+919363647520',
        email: 'contact.urbannest360@gmail.com'
    };

    @wire(getCompanyContactInfo)
    wiredContactInfo({ data, error }) {
        if (data) {
            this.contactSettings = { ...this.contactSettings, ...data };
        }
    }

    get displayAddress() {
        return this.customAddress || this.contactSettings.address;
    }

    get displayPhone() {
        return this.customPhone || this.contactSettings.phone;
    }

    get telHref() {
        const raw = (this.customPhone || this.contactSettings.phoneRaw || this.displayPhone || '').replace(/[^0-9+]/g, '');
        return `tel:${raw}`;
    }

    get displayEmail() {
        return this.customEmail || this.contactSettings.email;
    }

    get mailToHref() {
        return `mailto:${this.displayEmail}`;
    }

    handleLogoError() {
        this.isLogoFallback = true;
    }

    get currentYear() {
        return new Date().getFullYear();
    }
}