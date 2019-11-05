XmlBuilder.CustomParams.Row = createReactClass({

  propTypes: {
    param_name: PropTypes.string,
    param_value: PropTypes.string,
    index: PropTypes.number.isRequired,
    onRowDelete: PropTypes.func.isRequired
  },

  removeHandler: function (e) {
    // prevent refreshing page
    e.stopPropagation();
    e.nativeEvent.stopImmediatePropagation();

    var index = ReactDOM.findDOMNode(this.refs.index).value.trim();
    this.props.onRowDelete(Number(index));
  },

  render: function () {
    return (
      <tr>
        <td><input ref="paramName" name={"custom_params["+this.props.index+"][name]"} defaultValue={this.props.param_name} type="text"></input></td>
        <td><input ref="paramValue" name={"custom_params["+this.props.index+"][value]"} defaultValue={this.props.param_value} type="text"></input></td>
        <td className="add-remove-col">
          <input type="hidden" ref="index" value={this.props.index}></input>
          <a href="#" onClick={this.removeHandler}>
            <span className="glyphicon glyphicon-minus remove-icon"></span>
          </a>
        </td>
      </tr>
    );
  }

});