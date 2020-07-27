import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/widgets/poll_option_name_text_field.dart';

String nameLengthValidator(EditOptionTileInputValue value) {
  if (value.option.name.length < 2) {
    return 'Please enter text of 2 or more characters length.';
  }

  if (value.option.name.length > 100) {
    return 'Maximal length is 100 characters.';
  }

  return null;
}

FormFieldValidator<EditOptionTileInputValue> createValidator(
    FormFieldValidator<EditOptionTileInputValue> anotherValidator) {
  return (EditOptionTileInputValue value) {
    return nameLengthValidator(value) ?? (anotherValidator != null ? anotherValidator(value) : null);
  };
}

class EditOptionTileInputValue {
  PollOption option;
  bool addGlobally;

  EditOptionTileInputValue clone() {
    return EditOptionTileInputValue()
      ..option = option
      ..addGlobally = addGlobally;
  }
}

EditOptionTileInputValue ensureNotNullInitialValue(EditOptionTileInputValue initialValue) {
  return EditOptionTileInputValue()
    ..option = initialValue?.option ?? PollOption()
    ..addGlobally = initialValue?.addGlobally ?? false;
}

class EditOptionTile extends FormField<EditOptionTileInputValue> {
  EditOptionTile({
    Key key,
    EditOptionTileInputValue initialValue,
    FormFieldSetter<EditOptionTileInputValue> onSaved,
    FormFieldValidator<EditOptionTileInputValue> validator,
    InputDecoration decoration,
    bool autovalidate = false,
    bool showSaveButton = false,
    // The function is called when the form is valid and the save button is clicked
    void Function(EditOptionTileInputValue value) onSaveButtonClick,
    bool showDeleteButton = false,
    void Function(EditOptionTileInputValue value) onDeleteButtonClick,
    bool showAddGloballyOption = true,
    void Function(EditOptionTileInputValue value) onChanged,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: createValidator(validator),
          initialValue: ensureNotNullInitialValue(initialValue),
          autovalidate: autovalidate,
          builder: (FormFieldState<EditOptionTileInputValue> state) {
            final context = state.context;

            InputDecoration decWithError = (decoration ?? InputDecoration()).copyWith(
              errorText: state.hasError ? state.errorText : null,
              labelText: 'Option text',
            );

            return ListTile(
              leading: Container(height: double.infinity, child: Icon(Icons.add, size: 40, color: Colors.green)),
              title: _buildInputs(decWithError, state, onChanged, showAddGloballyOption),
              trailing: _buildActions(
                  showSaveButton, showDeleteButton, onDeleteButtonClick, onSaveButtonClick, state, context),
            );
          },
        );

  static Row _buildActions(
    bool showSaveButton,
    bool showDeleteButton,
    void onDeleteButtonClick(EditOptionTileInputValue value),
    void onSaveButtonClick(EditOptionTileInputValue value),
    FormFieldState<EditOptionTileInputValue> state,
    BuildContext context,
  ) {
    return showSaveButton || showDeleteButton
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDeleteButton)
                IconButton(
                  icon: Icon(Icons.delete),
                  iconSize: 40,
                  tooltip: 'Remove',
                  onPressed: () {
                    if (onDeleteButtonClick != null) {
                      onDeleteButtonClick(state.value);
                    }
                  },
                ),
              if (showSaveButton)
                IconButton(
                  icon: Icon(Icons.save),
                  color: Theme.of(context).primaryColor,
                  iconSize: 40,
                  tooltip: 'Add',
                  onPressed: () {
                    if (state.validate()) {
                      if (onSaveButtonClick != null) {
                        onSaveButtonClick(state.value);
                      }
                    }
                  },
                ),
            ],
          )
        : null;
  }

  static Column _buildInputs(
    InputDecoration decoration,
    FormFieldState<EditOptionTileInputValue> state,
    void onChanged(EditOptionTileInputValue value),
    bool showAddGloballyOption,
  ) {
    return Column(
      children: [
        PollOptionNameTextField(
          decoration: decoration,
          onNameChanged: (String value) {
            var updated = state.value.clone();
            updated.option = state.value.option.clone();
            updated.option.name = value;
            state.didChange(updated);
            if (onChanged != null) {
              onChanged(updated);
            }
          },
        ),
        if (showAddGloballyOption == true)
          CheckboxListTile(
            value: state.value.addGlobally,
            title: Text('Save this option for future polls'),
            onChanged: (bool value) {
              var updated = state.value.clone();
              updated.addGlobally = value;
              state.didChange(updated);
              if (onChanged != null) {
                onChanged(updated);
              }
            },
          ),
      ],
    );
  }
}
