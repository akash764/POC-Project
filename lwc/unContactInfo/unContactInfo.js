import { LightningElement, api, wire } from 'lwc';
import getCompanyContactInfo from '@salesforce/apex/UNProjectController.getCompanyContactInfo';

export default class UnContactInfo extends LightningElement {
    @api customAddress;
    @api customPhone;
    @api customEmail;
    @api customVisitorHours;

    contactSettings = {
        address: 'Level 12, Urban Horizon Center, IT Corridor, Chennai — 600096',
        phone: '+91 93636 47520',
        phoneRaw: '+919363647520',
        email: 'contact.urbannest360@gmail.com',
        visitorHours: 'Monday – Saturday: 9:30 AM – 6:30 PM (IST)'
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

    get displayVisitorHours() {
        return this.customVisitorHours || this.contactSettings.visitorHours;
    }
}