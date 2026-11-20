// ignore_for_file: deprecated_member_use

/// Web implementation: hands the prefilled email to the browser's mail
/// handler. Navigating the window to a mailto: URI opens the default
/// mail compose with the subject and body already filled in; the user
/// adds the recipient and attaches the photos in upload order.
import 'dart:html' as html;

void openMailCompose(Uri mailtoUri) {
  html.window.location.href = mailtoUri.toString();
}
