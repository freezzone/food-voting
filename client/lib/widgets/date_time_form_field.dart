import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:food_voting_app/utils/datetime_utils.dart';

class DateTimeFormField extends FormField<DateTime> {
  DateTimeFormField(
      {@required DateTime initialValue,
      @required DateTime firstDate,
      @required DateTime lastDate,
      FormFieldSetter<DateTime> onSaved,
      FormFieldValidator<DateTime> validator,
      InputDecoration decoration,
      bool autovalidate = false})
      : super(
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          autovalidate: autovalidate,
          builder: (FormFieldState<DateTime> state) {
            final context = state.context;
            final theme = Theme.of(context);

            var selectDateTime = () {
              var date = state.value ?? DateTime.now();

              var selectDate = () => showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );

              var selectTime = () => showTimePicker(
                    context: context,
                    initialTime: state.value != null ? TimeOfDay.fromDateTime(state.value) : TimeOfDay.now(),
                    cancelText: 'BACK',
                  );

              var selectDateTime = () async {
                while (true) {
                  var _date = await selectDate();
                  if (_date == null) {
                    return null;
                  }
                  date = _date;
                  var _time = await selectTime();
                  if (_time != null) {
                    return modifyDateTime(date, hour: _time.hour, minute: _time.minute);
                  }
                }
              };

              selectDateTime().then((result) {
                if (result != null) {
                  state.didChange(result);
                }
              });
            };

            InputDecoration decWithError = decoration != null
                ? decoration.copyWith(
                    errorText: state.hasError ? state.errorText : null,
                  )
                : null;

            return ListTile(
              title: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: selectDateTime,
                  child: InputDecorator(
                    decoration: decWithError,
                    expands: false,
                    child: Text(state.value == null ? '' : DateFormat.yMMMMEEEEd().add_Hm().format(state.value)),
                    isEmpty: state.value == null,
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.date_range),
                iconSize: 40,
                color: theme.primaryColor,
                onPressed: selectDateTime,
              ),
            );
          },
        );
}
