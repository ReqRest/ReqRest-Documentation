---
uid: guides_custom_serializers
---

# How to: Implementing Custom Serializers

## Introduction

When interacting with a web service, the data being transfered usually needs to be serialized to a
specific data transfer format (e.g. JSON, XML, SOAP, ...) before it can be sent.
This also holds true for most REST APIs.

As a result, ReqRest offers ways to serialize and deserialize POCOs to and from common formats
such as JSON. However, depending on what kind of API you are wrapping, a requirement could be that
you need to implement a custom data serialization mechanism for a specific data format.

This guide explains what the requirements for such custom serializers are and afterwards
shows an actual example of how to implement a custom XML serializer based on these information.  


## Serialization Members

ReqRest defines two central interfaces that deal with the serialization and deserialization of
objects. You can see the definitions below:

```csharp
public interface IHttpContentSerializer
{
    HttpContent? Serialize(object? content, Encoding? encoding);
}

public interface IHttpContentDeserializer
{
    Task<object?> DeserializeAsync(HttpContent? httpContent, Type contentType);
}
```

Since ReqRest is just supposed to be a wrapper around .NET's @"System.Net.Http.HttpClient" API, all
that it cares about is how an object can be converted to and from an @"System.Net.Http.HttpContent",
because both the @"System.Net.Http.HttpRequestMessage" and @"System.Net.Http.HttpResponseMessage"
store their body as an @"System.Net.Http.HttpContent" instance.


## Serializer Checklist

While the serialization interfaces above are rather trivial, there are a few points that nearly
every generic serializer should support:

* It should be able to correctly (de-)serialize the special @"ReqRest.Serializers.NoContent" type.
  This type represents an empty HTTP content and is supposed to be used when an API returns no content
  (for example after deleting a resource).
* Serializers should throw an @"ReqRest.Serializers.HttpContentSerializationException"
  when the (de-)serialization fails.
  This should be done so that users of the library only have to catch a single exception type without
  having to worry about what deserializing an API response may throw.
* Serializers use the specified encoding (if not null) or a default one.
* Serializers should do basic parameter validation.

> [!NOTE]
> These rules usually apply to generic serializers only, i.e. serializers which are able to serialize
> multiple different types (common examples are JSON or XML serializers).
> It could also happen that you need to write a serializer for a very specific type, e.g. a
> `StringSerializer`. In that case, the rules above don't necessarily have to be followed.


## Implementing an XML Serializer - The Hard Way

Using both the available interfaces and the guidelines from above, we can create a custom
XML serializer with a few lines of code:

```csharp
public class MyXmlHttpContentSerializer : IHttpContentSerializer, IHttpContentDeserializer
{
    public HttpContent? Serialize(object? content, Encoding? encoding)
    {
        encoding ??= Encoding.UTF8; // Note: encoding is not used in this example for simplicity.
                                    //       A perfect serializer uses it though.
        
        // Represent both 'null' and the special 'NoContent' type as "No HTTP Content".
        // Represent null like this to keep the example (and deserialization) simple.
        if (content is null || content.GetType() == typeof(NoContent))
        {
            return null;
        }

        try
        {
            XmlSerializer serializer = new XmlSerializer(content.GetType());
            using MemoryStream ms = new MemoryStream();
            serializer.Serialize(ms, content);
            return new ByteArrayContent(ms.ToArray());
        } 
        catch (Exception ex)
        {
            // The serializer may throw certain serialization exceptions.
            // Ideally, these are caught and wrapped into the special exception below.
            throw new HttpContentSerializationException(message: null, innerException: ex);
        }
    }

    public async Task<object?> DeserializeAsync(HttpContent? httpContent, Type contentType)
    {
        _ = contentType ?? throw ArgumentNullException(nameof(contentType));

        // If the user wants to deserialize NoContent, this must be handled by the serializer.
        // The XmlSerializer used below will have problems without this special handling.
        // Note: We could also require the httpContent to be null or empty here and throw an
        //       exception otherwise. This is not recommended though, because it leads to less stable
        //       code.
        if (contentType == typeof(NoContent))
        {
            return new NoContent();    
        }

        // We don't want to deserialize NoContent at this point, but the httpContent can still
        // be null. Simply map this to null.
        if (httpContent is null)
        {
            return null;
        }

        try
        {
            XmlSerializer serializer = new XmlSerializer(contentType);
            using Stream stream = await httpContent.ReadAsStreamAsync().ConfigureAwait(false);
            return serializer.Deserialize(stream);
        } 
        catch (Exception ex)
        {
            // Again, be sure to wrap any serialization exception into this special exception.
            throw new HttpContentSerializationException(message: null, innerException: ex);
        }
    }
}
```

Congratulations! You have just created your first custom serializer.
When looking at the code above, you may notice that there is a lot of boilerplate in there.
Most passages are universal to any kind of serializer, for example the exception and
@"ReqRest.Serializers.NoContent" handling.
For this reason, ReqRest provides you with the abstract 
@"ReqRest.Serializers.HttpContentSerializer" class which, when inherited
from, already takes care of most of these tasks.


## Implementing an XML Serializer - The Easy Way

Using the @"ReqRest.Serializers.HttpContentSerializer" mentioned above,
we can reduce the code of the custom XML serializer to this:

```csharp
public class MyXmlSerializer : HttpContentSerializer
{
    protected override HttpContent? SerializeCore(object? content, Encoding encoding)
    {
        if (content is null)
        {
            return null;
        }

        XmlSerializer serializer = new XmlSerializer(content.GetType());
        using MemoryStream ms = new MemoryStream();
        serializer.Serialize(ms, content);
        return new ByteArrayContent(ms.ToArray());
    }

    protected override async Task<object?> DeserializeCore(HttpContent? httpContent, Type contentType)
    {
        if (httpContent is null)
        {
            return null;
        }

        XmlSerializer serializer = new XmlSerializer(contentType);
        using MemoryStream stream = await httpContent.ReadAsStreamAsync().ConfigureAwait(false);
        return serializer.Deserialize(stream);
    }
}
```

As you can see, the required code got reduced by quite a bit, because the
@"ReqRest.Serializers.HttpContentSerializer" already takes care of

* handling @"ReqRest.Serializers.NoContent",
* handling serialization exceptions,
* using the default `UTF8` encoding, if no special encoding is given
* and finally, basic parameter validation.

Using this base class is thus the recommended way for implementing custom serializers.


## Integration with ReqRest

Now that the serializer has been created, there is still one important thing to do - integrating it
with the other classes that ReqRest provides. For example, have a look at the following pseudo-code
which lists some of the methods that integrate the 
@"ReqRest.Serializers.NewtonsoftJson.JsonHttpContentSerializer"
into ReqRest's fluent builder API:

```csharp
ApiRequest request;
request.SetJsonContent(...);
request.PostJson(...);
request.Receive<Foo>().AsJson(...);
```

These are only a few examples, but show how a serializer can be added to the API.
The following section shows how such methods are written, using the custom serializer from above.

> [!TIP]
> This guide can only show a few of the many possible extension methods.
> Consider having a look into the source code of one of the released serializers (e.g.
> `ReqRest.Serializers.NewtonsoftJson`) for a guideline on which methods should be implemented.


### Adding `Receive<T>().AsMyXml()`

The most important extension method to be written for a custom serializer is the `As...` method,
because it allows users to use the custom serializer within a request upgrade chain.
For the custom XML serializer, the result will allow the user to write code like this:

```csharp
BuildRequest()
    .Receive<TodoItem>().AsMyXml(forStatusCode: 200)
    .Receive<Error>().AsMyXml(StatusCodeRange.Errors);
```

Before showing how to write the extension method, a few words should be said about how the
`Receive` function works.

In essense, any call to an `ApiRequest<...>.Receive<TRequest>()` returns a new 
@"ReqRest.ResponseTypeInfoBuilder`1" instance.
This builder does one thing: It enhances the request which is being built with information about
when the type `TRequest` defined in `Receive<TRequest>` can be received and how it can be deserialized, 
if it gets received. For this sake, it provides the @"ReqRest.ResponseTypeInfoBuilder`1.Build(System.Func{ReqRest.Serializers.IHttpContentDeserializer},System.Collections.Generic.IEnumerable{ReqRest.Http.StatusCodeRange})"
method which accepts exactly this data. Once called, the builder returns the new request in the
upgrade chain and allows the user to continue building that request.

Using this information, we can write an extension method for the @"ReqRest.ResponseTypeInfoBuilder`1"
class which passes in our custom serializer for a specific set of status codes and afterwards returns
the newly upgraded request.

```csharp
public static class MyXmlResponseTypeInfoBuilderExtensions
{
    public static T AsMyXml<T>(this ResponseTypeInfoBuilder<T> builder, params StatusCodeRange[] forStatusCodes)
        where T : ApiRequestBase
    {
        _ = builder ?? throw new ArgumentNullException(nameof(builder));
        _ = forStatusCodes ?? throw new ArgumentNullException(nameof(forStatusCodes));

        // The ResponseTypeInfoBuilder expects a factory function which creates the serializer.
        // This is done, because there is no need to allocate a new serializer instance
        // if the API returns a status code that is not defined in forStatusCodes.
        return builder.Build(
            () => new MyXmlSerializer(),
            forStatusCodes               
        );                               
    }
}
```


### Adding utility methods

While the `AsMyXml(...)` method from above is the most important one, there are a lot of utility
methods that can be added. For example, it is useful to have the following methods available:

```csharp
BuildRequest().SetMyXmlContent(obj);
BuildRequest().PostMyXml(obj);
```

Implementing these is rather straightforward, because it simply means extending the available
builder interfaces. In addition, existing extension methods can be used.

```csharp
public static class MyXmlHttpContentBuilderExtensions
{
    public static T SetMyXmlContent<T>(this T builder, object? content, Encoding? encoding = null)
        where T : IHttpContentBuilder
    {
        _ = builder ?? throw new ArgumentNullException(nameof(builder));
        MyXmlSerializer serializer = new MyXmlSerializer();
        HttpContent httpContent = serializer.Serialize(content, encoding);
        return builder.SetContent(httpContent);
    }
}

public static class MyXmlHttpMethodBuilderExtensions
{
    public static T PostMyXml<T>(this T builder, object? content, Encoding? encoding = null)
        where T : IHttpMethodBuilder, IHttpContentBuilder
    {
        return builder.Post().SetMyXmlContent(content, encoding);
    }
}
```

Again, this list is not complete. Consider looking at what extension methods the predefined
serializers like `ReqRest.Serializers.NewtonsoftJson` provide and take these as a guideline,
depending on your needs. 