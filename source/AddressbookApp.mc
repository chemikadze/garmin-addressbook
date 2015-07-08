using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.System as Sys;

class EmptyAddressbookView extends Ui.View {

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

}

class EmptyAddressbookDelegate extends Ui.BehaviorDelegate {
    function onMenu() {
        var menu = new Rez.Menus.MainMenu();
        Ui.pushView(menu, new AddressbookMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}

class AddressbookMenuDelegate extends Ui.MenuInputDelegate {
    function onMenuItem(item) {
        if (item == :add_address) {
            Ui.pushView(new Ui.TextPicker(), new ContactEnteringDelegate(0, new ContactInformation(null, null, null)), Ui.SLIDE_UP);
        } else if (item == :phone_sync) {
            Sys.println("TODO phone sync");
        }
    }
}

class ContactInformation {
    var name, phone, address;
    function initialize(newName, newPhone, newAddress) {
        name = newName;
        phone = newPhone;
        address = newAddress;
    }
}

class ContactInformationView extends Ui.View {
    hidden var contact = null;

    function initialize(newContact) {
        contact = newContact;
    }
        
    function onLayout(dc) {
        var views = Rez.Layouts.ContactLayout(dc);
        setLayout(views);
    }
    
    function onShow() {
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        // TODO move coords to resources
        // TODO make fields optional
        dc.drawText(35, 60, Gfx.FONT_MEDIUM, contact.name, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(35, 102, Gfx.FONT_MEDIUM, contact.phone, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(35, 144, Gfx.FONT_MEDIUM, contact.address, Gfx.TEXT_JUSTIFY_LEFT);
    }

    function onHide() {
    }    
}

class ContactInformationDelegate extends Ui.BehaviorDelegate {
    hidden var contact = null;

    function initialize(newContact) {
        contact = newContact;
    }
    
    function onMenu() {
        Ui.pushView(new Rez.Menus.ContactMenu(), new ContactMenuDelegate(contact), Ui.SLIDE_UP);
    }
    
    function onBack() {    
    }
}

class ContactMenuDelegate extends Ui.MenuInputDelegate {
    hidden var contact;
    
    function initialize(newContact) {
        contact = newContact;
    }
    
    function onMenuItem(item) {
        if (item == :edit_contact) {
            var picker;
            if (contact.name == null) {
                picker = new Ui.TextPicker();
            } else {
                picker = new Ui.TextPicker(contact.name);
            }
            Ui.pushView(picker, new ContactEnteringDelegate(0, contact), Ui.SLIDE_UP);
        } else if (item == :delete_contact) {
            App.getApp().deleteContact(contact);
            Ui.pushView(new EmptyAddressbookView(), new EmptyAddressbookDelegate(), Ui.SLIDE_UP);
        }
    }
}

class ContactEnteringDelegate extends Ui.TextPickerDelegate {
    hidden var field, info;
    
    function initialize(newField, newInfo) {
        field = newField; 
        info = newInfo;    
    }
    
    function onTextEntered(text, changed) {
        var nextValue = null;
        if (field == 0) { info.name = text; nextValue = info.phone; }
        else if (field == 1) { info.phone = text; nextValue = info.address; } 
        else if (field == 2) { info.address = text; }
        
        if (field < 2) {            
            Ui.pushView(new Ui.TextPicker(nextValue), new ContactEnteringDelegate(field + 1, info), Ui.SLIDE_LEFT);            
        } else { 
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            App.getApp().saveContact(info);
            Ui.pushView(new ContactInformationView(info), new ContactInformationDelegate(info), Ui.SLIDE_LEFT);            
        }
    }
    
    function onCancel() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}

class AddressbookApp extends App.AppBase {

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }
    
    hidden var contact = null;
    
    function saveContact(newContact) {
        contact = newContact;
        if (contact != null) {
            setProperty("contact_0", dumpContact(contact));
            saveProperties();
        }        
    }
    
    function deleteContact(contactToRemove) {
        contact = null;
        deleteProperty("contact_0");
        saveProperties();
    } 

    //! Return the initial view of your application here
    function getInitialView() {
        loadProperties();
        var obj = getProperty("contact_0");
        if (obj != null) {
            contact = parseContact(obj);
            return [new ContactInformationView(contact), new ContactInformationDelegate(contact)];
        } else {
            return [ new EmptyAddressbookView(), new EmptyAddressbookDelegate() ];
        }                       
    }
    
    hidden function parseContact(o) {
        return new ContactInformation(o["name"], o["phone"], o["address"]);
    }
    
    hidden function dumpContact(o) {
        return {"name" => o.name, "phone" => o.phone, "address" => o.address};
    }

}