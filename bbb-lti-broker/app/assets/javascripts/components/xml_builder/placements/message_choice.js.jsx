XmlBuilder.Placements.MessageChoice = createReactClass({
    render: function() {
        if (this.props.messages) {
            var messages = this.props.messages;
            var title = this.props.title
            return (
                <select name={ this.props.placementKey + '_message_type' } >
                    {messages.map(function(message){
                        return (<option key={ title + '  Message Type' + message } name={ title + '  Message Type' } value={ message } >{ message }</option>);
                    })}
                </select>
            );
        } else {
            return false;
        }
    }
});
