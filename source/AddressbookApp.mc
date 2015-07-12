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
            var info = App.getApp().emptyContact();
            Ui.pushView(new Ui.TextPicker(info.name), new ContactEnteringDelegate(0, info, true), Ui.SLIDE_UP);
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
    
    function onNextPage() {
        var info = App.getApp().nextContact();        
        Ui.switchToView(new ContactInformationView(info), new ContactInformationDelegate(info), Ui.SLIDE_UP);
    }
    
    function onPreviousPage() {       
        var info = App.getApp().prevContact();
        Ui.switchToView(new ContactInformationView(info), new ContactInformationDelegate(info), Ui.SLIDE_DOWN);
    }
}

class ContactMenuDelegate extends Ui.MenuInputDelegate {
    hidden var contact;
    
    function initialize(newContact) {
        contact = newContact;
    }
    
    function onMenuItem(item) {
        if (item == :add_contact) {
            var picker = new Ui.TextPicker();
            contact = App.getApp().emptyContact();
            Ui.pushView(picker, new ContactEnteringDelegate(0, contact, true), Ui.SLIDE_UP);
        } else if (item == :edit_contact) {
            var picker;
            if (contact.name == null) {
                picker = new Ui.TextPicker();
            } else {
                picker = new Ui.TextPicker(contact.name);
            }
            Ui.pushView(picker, new ContactEnteringDelegate(0, contact, false), Ui.SLIDE_UP);
        } else if (item == :delete_contact) {
            var info = App.getApp().deleteCurrentContact();
            if (info != null) {
                Ui.pushView(new ContactInformationView(info), new ContactInformationDelegate(info), Ui.SLIDE_LEFT);
            } else {
                Ui.pushView(new EmptyAddressbookView(), new EmptyAddressbookDelegate(), Ui.SLIDE_UP);
            } 
        }
    }
}

class ContactEnteringDelegate extends Ui.TextPickerDelegate {
    hidden var field, info, createNew;
    
    function initialize(newField, newInfo, isCreateNew) {
        field = newField; 
        info = newInfo;    
        
        createNew = isCreateNew;
    }
    
    function onTextEntered(text, changed) {
        var nextValue = null;
        if (field == 0) { info.name = text; nextValue = info.phone; }
        else if (field == 1) { info.phone = text; nextValue = info.address; } 
        else if (field == 2) { info.address = text; }
        
        if (field < 2) {            
            Ui.pushView(new Ui.TextPicker(nextValue), new ContactEnteringDelegate(field + 1, info, createNew), Ui.SLIDE_LEFT);            
        } else {
            if (createNew) {
                App.getApp().addContact(info);
            } else {
                App.getApp().saveContact(info);
            }             
            Ui.switchToView(new ContactInformationView(info), new ContactInformationDelegate(info), Ui.SLIDE_LEFT);            
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
        setProperty("current_contact", currentContactId);
        saveProperties();
    }
    
    hidden var currentContactId;
    hidden var nextContactId;
    hidden var prevContactId;
    hidden var maxContactId;
    
    function emptyContact() {
        return new ContactInformation("Nam", "Tel", "Adr");
    }
    
    function addContact(contact) {
        if (contact != null) {
            Sys.println("saving " + maxContactId + " curr " + currentContactId + " prev " + prevContactId + " next " + nextContactId);
            setProperty("contact_" + maxContactId, dumpContact(currentContactId, nextContactId, contact));
            var currentContactInfo = loadContactInfo(currentContactId);
            var nextContactInfo = loadContactInfo(nextContactId);
            var newPrevId;                
            if (nextContactId == currentContactId && prevContactId == currentContactId) {
                // there were only one contact, tail inserted
                setProperty("contact_" + currentContactId, dumpContact(maxContactId, maxContactId, currentContactInfo[2])); 
            } else {
                setProperty("contact_" + currentContactId, dumpContact(currentContactInfo[0], maxContactId, currentContactInfo[2]));
	            setProperty("contact_" + nextContactId, dumpContact(maxContactId, nextContactInfo[1], nextContactInfo[2]));
            }
            prevContactId = currentContactId;
            currentContactId = maxContactId;
            maxContactId += 1; 
            setProperty("max_contact", maxContactId);            
            saveProperties();
            Sys.println("now on " + currentContactId + " prev " + prevContactId + " next " + nextContactId);
        }        
    }  
    
    function saveContact(contact) {
        if (contact != null) {
            setProperty("contact_" + currentContactId, dumpContact(prevContactId, nextContactId, contact));
            saveProperties();
        }        
    }
    
    function nextContact() {        
        var contactInfo = loadContactInfo(nextContactId);
        if (contactInfo != null) {
	        currentContactId = nextContactId;
	        prevContactId = contactInfo[0];
	        nextContactId = contactInfo[1];
	    }
        return contactInfo[2];
    }
    
    function prevContact() {        
        var contactInfo = loadContactInfo(prevContactId);
        if (contactInfo != null) {
	        currentContactId = prevContactId;
	        prevContactId = contactInfo[0];
	        nextContactId = contactInfo[1];
        }
        return contactInfo[2];
    }
    
    function deleteCurrentContact() {                       
        Sys.println("deleting " + maxContactId + " curr " + currentContactId + " prev " + prevContactId + " next " + nextContactId);
        var prevContactInfo = loadContactInfo(prevContactId);
        var nextContactInfo = loadContactInfo(nextContactId);
        deleteProperty("contact_" + currentContactId);
        if (prevContactId != nextContactId) {
            setProperty("contact_" + prevContactId, dumpContact(prevContactInfo[0], nextContactId, prevContactInfo[2]));
	        setProperty("contact_" + nextContactId, dumpContact(prevContactId, nextContactInfo[1], nextContactInfo[2]));	        
            prevContactId = prevContactInfo[0];
        } else if (prevContactId != currentContactId) {
            setProperty("contact_" + prevContactId, dumpContact(prevContactId, prevContactId, prevContactInfo[2]));
            currentContactId = prevContactId;
            nextContactId = prevContactId;
        } else {
            clearProperties();
            currentContactId = 0;
            prevContactId = 0;
            nextContactId = 0;
            maxContactId = 0;
            return null;
        }            
        currentContactId = prevContactId;
        setProperty("current_contact", prevContactId);                   
        saveProperties();
        return prevContactInfo[2];
    }
    
    hidden function loadContactInfo(id) {
        Sys.println("loading " + id);
        var obj = getProperty("contact_" + id);
        if (obj != null) {        
	        var nextContactId = obj.get("next");
	        var prevContactId = obj.get("prev"); 
	        var contact = parseContact(obj);
	        Sys.println(contact.name + " next " + nextContactId + " prev " + prevContactId);
	        return [prevContactId, nextContactId, contact];
	    } else {
	        return null;
	    }
    }     

    //! Return the initial view of your application here
    function getInitialView() {
        // clearProperties();        
        loadProperties();        
        currentContactId = orElse(getProperty("current_contact"), 0);
        maxContactId = orElse(getProperty("max_contact"), 0);        
        var contactInfo = loadContactInfo(currentContactId);                                
        if (contactInfo != null) {
            var contact = contactInfo[2];
            prevContactId = contactInfo[0];
            nextContactId = contactInfo[1];
            return [new ContactInformationView(contact), new ContactInformationDelegate(contact)];
        } else {
            prevContactId = currentContactId;
            nextContactId = currentContactId;
            return [ new EmptyAddressbookView(), new EmptyAddressbookDelegate() ];
        }                       
    }
    
    hidden function parseContact(o) {
        return new ContactInformation(o["name"], o["phone"], o["address"]);
    }
    
    hidden function dumpContact(prevId, nextId, o) {
        return {"name" => o.name, "phone" => o.phone, "address" => o.address, "next" => nextId, "prev" => prevId};
    }
    
    hidden function orElse(a, b) {
        if (a == null) {
          return b;          
        } else {
          return a;
        }
    }

}