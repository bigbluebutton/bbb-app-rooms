XmlBuilder.Placements.Row = createReactClass({

  propTypes: {
    placementKey: PropTypes.string
  },

  render: function () {
    return (
      <tr>
        <td className="text-center checkbox-col">
          <label className="show">
            <input type="checkbox" className="placement" name={ "placements[" + this.props.placementKey + "][enabled]"}/>
          </label>
        </td>
        <td> {this.props.children} </td>
        <td className="message-type">
            <XmlBuilder.Placements.MessageChoice title={ this.props.children } placementKey={ this.props.placementKey } messages={ this.props.message }/>
        </td>
      </tr>
    );
  }

});
