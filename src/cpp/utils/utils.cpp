#ifdef ASMDOM_JS_SIDE
#include "utils.hpp"
#include <locale>
#include <string>
#include <vector>

namespace asmdom
{

    std::wstring utf8_to_wstring(const std::string& str)
    {
        std::vector<wchar_t> buf(str.size());
        std::use_facet<std::ctype<wchar_t>>(std::locale()).widen(str.data(), str.data() + str.size(), buf.data());
        return std::wstring(buf.data(), buf.size());
    };

    std::string wstring_to_utf8(const std::wstring& str)
    {
        std::vector<char> buf(str.size());
        std::use_facet<std::ctype<wchar_t>>(std::locale()).narrow(str.data(), str.data() + str.size(), '?', buf.data());
        return std::string(buf.data(), buf.size());
    };

}
#endif