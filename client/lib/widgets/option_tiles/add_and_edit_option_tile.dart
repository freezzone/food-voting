import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:food_voting_app/widgets/option_tiles/add_option_tile.dart';
import 'package:food_voting_app/widgets/option_tiles/edit_option_tile.dart';
import 'package:provider/provider.dart';

class AddAndEditOptionTile extends StatefulWidget {
  final bool wouldBeFirstOption;
  final bool showAddGloballyOption;

  /// Called when the option is valid and "Save option" button is clicked
  final void Function(EditOptionTileInputValue value) onSave;
  final EditOptionTileInputValue initialValue;

  AddAndEditOptionTile({
    Key key,
    this.onSave,
    this.wouldBeFirstOption = false,
    this.showAddGloballyOption = true,
    this.initialValue,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddAndEditOptionTileState();
  }
}

class _AddAndEditOptionTileState extends State<AddAndEditOptionTile> {
  bool _isWriting = false;
  var _pollOptionsStream;

  @override
  void initState() {
    super.initState();
    final pollService = context.read<PollService>();
    _pollOptionsStream = pollService.getGlobalOptions();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PollOption>>(
      stream: _pollOptionsStream,
      initialData: [],
      builder: (context, snapshot) {
        return _isWriting == false ? _buildAddOptionTile() : _buildEditOptionTile();
      },
    );
  }

  Widget _buildEditOptionTile() {
    return EditOptionTile(
      initialValue: widget.initialValue,
      showDeleteButton: true,
      onDeleteButtonClick: (_) {
        setState(() {
          _isWriting = false;
        });
      },
      showAddGloballyOption: widget.showAddGloballyOption,
      showSaveButton: true,
      onSaveButtonClick: _saveOption,
    );
  }

  Widget _buildAddOptionTile() {
    return AddOptionTile(
      wouldBeFirstOption: widget.wouldBeFirstOption,
      onAddOption: () {
        setState(() {
          _isWriting = true;
        });
      },
    );
  }

  void _saveOption(EditOptionTileInputValue value) {
    setState(() {
      _isWriting = false;
    });

    if (this.widget.onSave != null) {
      this.widget.onSave(value);
    }
  }
}
