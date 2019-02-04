//
//  DSFFloatLabelledTextField.swift
//  DSFFloatLabelledTextControls
//
//  Created by Darren Ford on 4/2/19.
//  Copyright © 2019 Darren Ford. All rights reserved.
//

import Cocoa

class DSFFloatLabelledTextFieldCell: NSTextFieldCell
{
	var topOffset: CGFloat = 0

	override func titleRect(forBounds rect: NSRect) -> NSRect
	{
		let offset: CGFloat = self.isBezeled ? 5 : 1
		return NSRect(x: rect.origin.x, y: rect.origin.y + self.topOffset - offset, width: rect.width, height: rect.height)
	}

	override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?)
	{
		let offset: CGFloat = self.isBezeled ? 5 : 1
		let insetRect = NSRect(x: rect.origin.x, y: rect.origin.y + topOffset - offset, width: rect.width, height: rect.height)
		super.edit(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, event: event)
	}

	override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int)
	{
		let offset: CGFloat = self.isBezeled ? 5 : 1
		let insetRect = NSRect(x: rect.origin.x, y: rect.origin.y + topOffset - offset, width: rect.width, height: rect.height)
		super.select(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
	}

	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView)
	{
		let offset: CGFloat = self.isBezeled ? 5 : 1
		let insetRect = NSRect(x: cellFrame.origin.x, y: cellFrame.origin.y + topOffset - offset, width: cellFrame.width, height: cellFrame.height)
		super.drawInterior(withFrame: insetRect, in: controlView)
	}
}

@IBDesignable open class DSFFloatLabelledTextField: NSTextField
{
	@IBInspectable public var placeholderTextSize: CGFloat = 13
	{
		didSet
		{
			self.floatingLabel?.font = NSFont.systemFont(ofSize: self.placeholderTextSize)
			self.reconfigureControl()
		}
	}

	/// Floating label
	private var floatingLabel: NSTextField?

	/// Is the label currently showing
	private var isShowing: Bool = false

	/// Constraint to tie the label to the top of the control
	private var floatingTop: NSLayoutConstraint?

	/// Height of the control
	private var heightConstraint: NSLayoutConstraint?

	private var fontObserver: NSKeyValueObservation?
	private var placeholderObserver: NSKeyValueObservation?

	open func setFonts(primary: NSFont, secondary: NSFont)
	{
		self.floatingLabel?.font = secondary
		self.font = primary
	}

	open override func viewDidMoveToWindow()
	{
		self.commoninit()

		/// Listen to changes in the main font so we can reconfigure to match
		self.fontObserver = self.observe(\.font, options: [.new]) { (field, state) in
			self.reconfigureControl()
		}

		/// Listen to changes in the placeholder text so we can reflect it in the floater
		self.placeholderObserver = self.observe(\.placeholderString, options: [.new], changeHandler: { (field, state) in
			self.floatingLabel?.stringValue = self.placeholderString!
			self.reconfigureControl()
		})
	}

	/// Change the layout if any changes occur
	private func reconfigureControl()
	{
		if self.currentlyBeingEdited()
		{
			self.window?.endEditing(for: nil)
		}
		self.fieldCell().topOffset = self.placeholderHeight()

		self.expandFrame()
		self.needsLayout = true
	}

	private func commoninit()
	{
		self.wantsLayer = true
		self.translatesAutoresizingMaskIntoConstraints = false
		self.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		self.setContentHuggingPriority(.defaultLow, for: .horizontal)
		self.usesSingleLineMode = true

		self.delegate = self

		let label = NSTextField()
		label.wantsLayer = true
		label.isEditable = false
		label.isSelectable = false
		label.isEnabled = true
		label.isBezeled = false
		label.isBordered = false
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = NSFont.systemFont(ofSize: self.placeholderTextSize)
		label.textColor = NSColor.controlAccentColor
		label.stringValue = self.placeholderString ?? ""
		label.alphaValue = 0.0
		label.alignment = self.alignment
		label.drawsBackground = false
		self.addSubview(label)
		self.floatingLabel = label

		self.floatingTop = NSLayoutConstraint(
			item: self.floatingLabel!, attribute: .top,
			relatedBy: .equal,
			toItem: self, attribute: .top,
			multiplier: 1.0, constant: 10)
		self.addConstraint(self.floatingTop!)

		var x = NSLayoutConstraint(
			item: label, attribute: .leading,
			relatedBy: .equal,
			toItem: self, attribute: .leading,
			multiplier: 1.0, constant: self.isBezeled ? 4 : 0)
		self.addConstraint(x)
		x = NSLayoutConstraint(
			item: label, attribute: .trailing,
			relatedBy: .equal,
			toItem: self, attribute: .trailing,
			multiplier: 1.0, constant: self.isBezeled ? -4 : 0)
		self.addConstraint(x)

		self.heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.controlHeight())
		self.addConstraint(self.heightConstraint!)

		let c = DSFFloatLabelledTextFieldCell()
		c.topOffset = self.placeholderHeight()

		c.isEditable = true
		c.wraps = false
		c.usesSingleLineMode = true
		c.placeholderString = self.placeholderString
		c.title = self.stringValue
		c.font = self.font
		c.isBordered = self.isBordered
		c.isBezeled = self.isBezeled
		c.bezelStyle = self.bezelStyle
		c.isScrollable = true
		c.isContinuous = self.isContinuous
		c.alignment = self.alignment
		c.formatter = self.formatter

		self.cell? = c

		self.expandFrame()
	}

	/// Returns the height of the placeholder text
	private func placeholderHeight() -> CGFloat
	{
		let text: NSString = self.placeholderString! as NSString
		let rect = text.boundingRect(with: NSSize(width: 0, height: 0), options: [], attributes: [.font: self.floatingLabel!.font!], context: nil)
		return rect.height
	}

	/// Returns the height of the primary (editable) text
	private func textHeight() -> CGFloat
	{
		let text: NSString = self.placeholderString! as NSString
		let rect = text.boundingRect(with: NSSize(width: 0, height: 0), options: [], attributes: [.font: self.font!], context: nil)
		return rect.height
	}

	/// Returns the total height of the control given the font settings
	private func controlHeight() -> CGFloat
	{
		return self.textHeight() + self.placeholderHeight()
	}

	/// Rebuild the frame of the text field to match the new settings
	private func expandFrame()
	{
		var x = self.frame.size
		x.height = self.controlHeight()
		self.setFrameSize(x)

		self.heightConstraint?.constant = self.controlHeight()

		self.needsDisplay = true
		self.needsLayout = true
	}
}

// MARK: - Focus and editing

extension DSFFloatLabelledTextField: NSTextFieldDelegate
{
	public func controlTextDidChange(_ obj: Notification)
	{
		guard let field = obj.object as? NSTextField else
		{
			return
		}

		if field.stringValue.count > 0 && !self.isShowing
		{
			self.showPlaceholder()
		}
		else if field.stringValue.count == 0 && self.isShowing
		{
			self.hidePlaceholder()
		}
	}

	fileprivate func amIInFocus() -> Bool
	{
		if let fr = self.window?.firstResponder as? NSTextView,
			self.window?.fieldEditor(false, for: nil) != nil,
			fr.delegate === self
		{
			return true
		}
		return false
	}

	override open func becomeFirstResponder() -> Bool
	{

		let x = super.becomeFirstResponder()
		if x && amIInFocus()
		{
			self.floatingLabel?.textColor = NSColor.controlAccentColor
			self.floatingLabel?.needsDisplay = true
		}
		return x
	}

	open func controlTextDidEndEditing(_ obj: Notification) {
		self.floatingLabel?.textColor = NSColor.placeholderTextColor
	}


	private func fieldCell() -> DSFFloatLabelledTextFieldCell
	{
		return self.cell as! DSFFloatLabelledTextFieldCell
	}

	/// If we are currently being edited (has focus) then lose focus BEFORE the changes
	private func currentlyBeingEdited() -> Bool
	{
		if let responder = self.window?.firstResponder,
			let view = responder as? NSTextView,
			view.isFieldEditor, view.delegate === self
		{
			return true
		}
		return false
	}
}

// MARK: - Animations

extension DSFFloatLabelledTextField
{
	fileprivate func showPlaceholder()
	{
		self.isShowing = true
		NSAnimationContext.runAnimationGroup({ context in
			context.allowsImplicitAnimation = true
			context.duration = 0.4
			self.floatingTop?.constant = 0
			self.floatingLabel?.alphaValue = 1.0
			self.layoutSubtreeIfNeeded()
		}, completionHandler: {

			//
		})
	}

	fileprivate func hidePlaceholder()
	{
		self.isShowing = false
		NSAnimationContext.runAnimationGroup({ context in
			context.allowsImplicitAnimation = true
			context.duration = 0.4
			self.floatingTop?.constant = self.textHeight() / 1.5
			self.floatingLabel?.alphaValue = 0.0
			self.layoutSubtreeIfNeeded()
		}, completionHandler: {
			//
		})
	}
}
